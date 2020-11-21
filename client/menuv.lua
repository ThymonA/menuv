----------------------- [ MenuV ] -----------------------
-- GitHub: https://github.com/ThymonA/menuv/
-- License: GNU General Public License v3.0
--          https://choosealicense.com/licenses/gpl-3.0/
-- Author: Thymon Arens <contact@arens.io>
-- Name: MenuV
-- Version: 1.0.0
-- Description: FiveM menu libarary for creating menu's
----------------------- [ MenuV ] -----------------------
local assert = assert
---@type Utilities
local U = assert(Utilities)
local INSERT = assert(table.insert)
local DECODE = assert(json.decode)
local LOWER = assert(string.lower)
local UPPER = assert(string.upper)
local RAWSET = assert(rawset)
local RAWGET = assert(rawget)

--- FiveM Globals
local REGISTER_NUI_CALLBACK = assert(RegisterNUICallback)
local SEND_NUI_MESSAGE = assert(SendNUIMessage)
local LOAD_RESOURCE_FILE = assert(LoadResourceFile)
local REGISTER_KEY_MAPPING = assert(RegisterKeyMapping)
local REGISTER_COMMAND = assert(RegisterCommand)
local CREATE_THREAD = assert(Citizen.CreateThread)
local WAIT = assert(Citizen.Wait)

--- VARIABLES OF MENUV
local MENUV_TABLE = {
    ---@type Menu|nil
    CURRENT_MENU = nil,
    ---@type string
    CURRENT_UPDATE_UUID = nil,
    ---@type string[]
    PARENT_MENUS = {},
    ---@type boolean
    LOADED = false,
    ---@type table<string, string>
    TRANSLATIONS = {},
    ---@type string
    LANGUAGE = U:Ensure(MENUV_CONFIG.Language, 'en'),
    ---@type table<string, table>
    KEYS = setmetatable({ data = {}, __class = 'MENUV_KEYS', __type = 'KEYS' }, {
        __index = function(t, k)
            return RAWGET(t.data, k)
        end,
        __newindex = function(t, k, v)
            local key = U:Ensure(k, 'unknown')

            if (key == 'unknown') then return end

            local rawKey = RAWGET(t.data, key)
            local keyExists = rawKey ~= nil
            local previeusState = U:Ensure((rawKey or {}).status, false)
            local newState = U:Ensure(v, false)

            if (keyExists) then
                RAWSET(t.data[key], 'status', newState)

                if (previeusState ~= newState) then
                    local trigger = newState and not previeusState and 'KEY_PRESSED' or 'KEY_RELEASED'
                    local action = U:Ensure(rawKey.action, 'UNKNOWN')

                    SEND_NUI_MESSAGE({
                        action = trigger,
                        key = action
                    })
                end
            end
        end,
        __call = function(t, key, action)
            key = U:Ensure(key, 'unknown')
            action = U:Ensure(action, 'UNKNOWN')

            if (key == 'unknown') then return end

            local rawKey = RAWGET(t.data, key)
            local keyExists = rawKey ~= nil

            if (keyExists) then return end

            RAWSET(t.data, key, { status = false, action = action })
        end
    })
}

--- LUA METATABLE OF MENUV
local MENUV_META = {}

--- MENUV MAIN CLASS
---@class MENUV_MAIN
local MENUV_MAIN = setmetatable(MENUV_TABLE, MENUV_META)

--- Load all translations
function MENUV_MAIN:LOAD_TRANSLATIONS()
    local path = ('languages/%s.json'):format(self.LANGUAGE)
    local raw = LOAD_RESOURCE_FILE('menuv', path)

    if (raw) then
        local data = DECODE(raw)

        if (data) then
            self.TRANSLATIONS = U:Ensure(data.translations, {})
        end
    end
end

--- Open a menu
---@param menu Menu Menu of MenuV
---@param cb function Trigger `callback` when menu has been opened
function MENUV_MAIN:OPEN(menu, cb)
    if (U:Typeof(menu) ~= 'Menu') then return end

    cb = U:Ensure(cb, function() end)

    if (not self.LOADED) then
        CREATE_THREAD(function()
            repeat WAIT(0) until self.LOADED

            self:OPEN(menu, cb)
        end)
    else
        if (self.CURRENT_MENU ~= nil) then
            if (self.PARENT_MENUS == nil) then self.PARENT_MENUS = {} end

            INSERT(self.PARENT_MENUS, self.CURRENT_MENU)

            self.CURRENT_MENU:RemoveOnEvent('update', self.CURRENT_UPDATE_UUID)
        end

        self.CURRENT_MENU = menu
        self.CURRENT_UPDATE_UUID = self.CURRENT_MENU:On('update', function(m, k, v)
            k = U:Ensure(k, 'unknown')

            if (k == 'Title' or k == 'title') then
                v = U:Ensure(v, 'MenuV')

                SEND_NUI_MESSAGE({
                    action = 'UPDATE_TITLE',
                    title = v
                })
            elseif (k == 'Subtitle' or k == 'subtitle') then
                v = U:Ensure(v, '')

                SEND_NUI_MESSAGE({
                    action = 'UPDATE_SUBTITLE',
                    subtitle = v
                })
            end
        end)

        SEND_NUI_MESSAGE({
            action = 'OPEN_MENU',
            menu = menu:ToTable()
        })

        cb()
    end
end

--- Register a `action` with custom keybind
---@param action string Action like: UP, DOWN, LEFT...
---@param description string Description of keybind
---@param defaultType string Type like: keyboard, mouse etc.
---@param defaultKey string Default key for this keybind
function MENUV_MAIN:REGISTER_KEY(action, description, defaultType, defaultKey)
    description = U:Ensure(description, 'unknown')
    defaultType = U:Ensure(defaultType, 'keyboard')
    defaultKey = U:Ensure(defaultKey, 'F12')
    action = U:Ensure(action, 'UNKNOWN')

    action = U:Replace(action, ' ', '_')
    action = UPPER(action)

    if (self.KEYS ~= nil and self.KEYS[action] ~= nil) then return end

    self.KEYS(action, action)

    REGISTER_KEY_MAPPING(LOWER(('+menuv_%s'):format(action)), description, defaultType, defaultKey)
    REGISTER_COMMAND(LOWER(('+menuv_%s'):format(action)), function() MENUV_MAIN.KEYS[action] = true end)
    REGISTER_COMMAND(LOWER(('-menuv_%s'):format(action)), function() MENUV_MAIN.KEYS[action] = false end)
end

--- Load translation
---@param translation string Translation key
---@return string Translation
function MENUV_MAIN:T(translation)
    translation = U:Ensure(translation, 'unknown')

    return U:Ensure(self.TRANSLATIONS[translation], 'MISSING TRANSLATION')
end

--- Set `LOADED` as `true` when `MenuV` is loaded
REGISTER_NUI_CALLBACK('loaded', function(_, cb)
    MENUV_MAIN.LOADED = true
    cb('ok')
end)

--- Make `MENUV_MAIN` global accessible
_G.MENUV_MAIN = MENUV_MAIN
_ENV.MENUV_MAIN = MENUV_MAIN

local MENUV_OPEN = function(menu, cb)
    MENUV_MAIN:OPEN(menu, cb)
end

--- Export functions
exports('open', MENUV_OPEN)
_G.MENUV_OPEN = MENUV_OPEN
_ENV.MENUV_OPEN = MENUV_OPEN

--- Load translations
MENUV_MAIN:LOAD_TRANSLATIONS()

--- Register all keybinds
MENUV_MAIN:REGISTER_KEY('UP', MENUV_MAIN:T('keybind_key_up'), 'KEYBOARD', 'UP')
MENUV_MAIN:REGISTER_KEY('DOWN', MENUV_MAIN:T('keybind_key_down'), 'KEYBOARD', 'DOWN')
MENUV_MAIN:REGISTER_KEY('LEFT', MENUV_MAIN:T('keybind_key_left'), 'KEYBOARD', 'LEFT')
MENUV_MAIN:REGISTER_KEY('RIGHT', MENUV_MAIN:T('keybind_key_right'), 'KEYBOARD', 'RIGHT')
MENUV_MAIN:REGISTER_KEY('ENTER', MENUV_MAIN:T('keybind_key_enter'), 'KEYBOARD', 'RETURN')
MENUV_MAIN:REGISTER_KEY('CLOSE', MENUV_MAIN:T('keybind_key_close'), 'KEYBOARD', 'ESCAPE')

--- Mark this resource as loaded
_G.MENUV_LOADED = true
_ENV.MENUV_LOADED = true