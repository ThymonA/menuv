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
local REMOVE = assert(table.remove)
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
local IS_SCREEN_FADED_OUT = assert(IsScreenFadedOut)
local IS_PAUSE_MENU_ACTIVE = assert(IsPauseMenuActive)

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
    ---@type number
    THREAD_TIME = 500,
    ---@type boolean
    THREAD_ACTIVE = false,
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

        self.THREAD_TIME = 250
        self:MAIN_THREAD()
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

--- Create a thread for showing / hiding menu when required
function MENUV_MAIN:MAIN_THREAD()
    if (self.THREAD_ACTIVE) then return end

    self.THREAD_ACTIVE = true

    CREATE_THREAD(function()
        local LAST_STATE = false

        while true do
            WAIT(MENUV_MAIN.THREAD_TIME)

            if (MENUV_MAIN.CURRENT_MENU ~= nil) then
                local newState = IS_SCREEN_FADED_OUT() or IS_PAUSE_MENU_ACTIVE()

                if (newState ~= LAST_STATE) then
                    SEND_NUI_MESSAGE({
                        action = 'UPDATE_STATUS',
                        status = not newState
                    })
                end

                LAST_STATE = newState
            else
                MENUV_MAIN.THREAD_TIME = 500
                MENUV_MAIN.THREAD_ACTIVE = false
                return
            end
        end
    end)
end

--- Set `LOADED` as `true` when `MenuV` is loaded
REGISTER_NUI_CALLBACK('loaded', function(_, cb)
    MENUV_MAIN.LOADED = true
    cb('ok')
end)

--- This event will be triggered when `ENTER` key is used
REGISTER_NUI_CALLBACK('submit', function(info, cb)
    local uuid = U:Ensure(info.uuid, '00000000-0000-0000-0000-000000000000')

    cb('ok')

    if (MENUV_MAIN.CURRENT_MENU == nil) then return end

    --- @param option Item
    for key, option in pairs(MENUV_MAIN.CURRENT_MENU.Items) do
        if (option.UUID == uuid) then
            if (option.__type == 'confirm' or option.__type == 'checkbox') then
                option.Value = U:Ensure(info.value, false)
            elseif (option.__type == 'range') then
                option.Value = U:Ensure(info.value, option.Min)
            elseif (option.__type == 'slider') then
                option.Value = (U:Ensure(info.value, 0) + 1)
            end

            MENUV_MAIN.CURRENT_MENU:Trigger('select', option)

            if (option.__type == 'button' or option.__type == 'menu') then
                MENUV_MAIN.CURRENT_MENU.Items[key]:Trigger('select')
            elseif (option.__type == 'range') then
                MENUV_MAIN.CURRENT_MENU.Items[key]:Trigger('select', option.Value)
            elseif (option.__type == 'slider') then
                local selectedOption = MENUV_MAIN.CURRENT_MENU.Items[key].Values[option.Value] or nil

                if (selectedOption == nil) then return end

                MENUV_MAIN.CURRENT_MENU.Items[key]:Trigger('select', selectedOption.Value)
            end
            return
        end
    end
end)

--- This event will be triggered when `CLOSE` key is used
REGISTER_NUI_CALLBACK('close', function(info, cb)
    local uuid = U:Ensure(info.uuid, '00000000-0000-0000-0000-000000000000')

    if (MENUV_MAIN.CURRENT_MENU == nil or MENUV_MAIN.CURRENT_MENU.UUID ~= uuid) then
        cb('ok')
        return
    end

    MENUV_MAIN.CURRENT_MENU:RemoveOnEvent('update', MENUV_MAIN.CURRENT_UPDATE_UUID)
    MENUV_MAIN.CURRENT_MENU = nil

    if (#MENUV_MAIN.PARENT_MENUS <= 0) then
        MENUV_MAIN.THREAD_TIME = 500
        cb('ok')
        return
    end

    local last_menu = MENUV_MAIN.PARENT_MENUS[#MENUV_MAIN.PARENT_MENUS] or nil

    REMOVE(MENUV_MAIN.PARENT_MENUS, #MENUV_MAIN.PARENT_MENUS)

    if (last_menu ~= nil) then
        MENUV_MAIN:OPEN(last_menu, function()
            cb('ok')
        end)
    else
        cb('ok')
    end
end)

REGISTER_NUI_CALLBACK('switch', function(info, cb)
    local prev_uuid = U:Ensure(info.prev, '00000000-0000-0000-0000-000000000000')
    local next_uuid = U:Ensure(info.next, '00000000-0000-0000-0000-000000000000')
    local prev_item = nil
    local next_item = nil

    cb('ok')

    if (MENUV_MAIN.CURRENT_MENU == nil) then return end

    for key, option in pairs(MENUV_MAIN.CURRENT_MENU.Items) do
        if (option.UUID == prev_uuid) then
            prev_item = option

            MENUV_MAIN.CURRENT_MENU.Items[key]:Trigger('leave')
        end

        if (option.UUID == next_uuid) then
            next_item = option

            MENUV_MAIN.CURRENT_MENU.Items[key]:Trigger('enter')
        end
    end

    if (prev_item ~= nil and next_item ~= nil) then
        MENUV_MAIN.CURRENT_MENU:Trigger('switch', next_item, prev_item)
    end
end)

REGISTER_NUI_CALLBACK('update', function(info, cb)
    local uuid = U:Ensure(info.uuid, '00000000-0000-0000-0000-000000000000')

    cb('ok')

    if (MENUV_MAIN.CURRENT_MENU == nil) then return end

    --- @param option Item
    for key, option in pairs(MENUV_MAIN.CURRENT_MENU.Items) do
        if (option.UUID == uuid) then
            local newValue, oldValue = nil, nil

            if (option.__type == 'confirm' or option.__type == 'checkbox') then
                newValue = U:Ensure(info.now, false)
                oldValue = U:Ensure(info.prev, false)
            elseif (option.__type == 'range') then
                newValue = U:Ensure(info.now, option.Min)
                oldValue = U:Ensure(info.prev, option.Min)
            elseif (option.__type == 'slider') then
                newValue = (U:Ensure(info.now, 0) + 1)
                oldValue = (U:Ensure(info.prev, 0) + 1)
            end

            if (U:Any(option.__type, { 'button', 'menu', 'label' }, 'value')) then
                return
            end

            MENUV_MAIN.CURRENT_MENU:Trigger('update', option, newValue, oldValue)
            MENUV_MAIN.CURRENT_MENU.Items[key]:Trigger('change', newValue, oldValue)
            return
        end
    end
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
MENUV_MAIN:REGISTER_KEY('CLOSE', MENUV_MAIN:T('keybind_key_close'), 'KEYBOARD', 'BACK')

--- Mark this resource as loaded
_G.MENUV_LOADED = true
_ENV.MENUV_LOADED = true