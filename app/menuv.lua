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
local lower = assert(string.lower)
local upper = assert(string.upper)
local decode = assert(json.decode)
local rawget = assert(rawget)
local rawset = assert(rawset)
local setmetatable = assert(setmetatable)

--- FiveM globals
local GetInvokingResource = assert(GetInvokingResource)
local LoadResourceFile = assert(LoadResourceFile)
local RegisterKeyMapping = assert(RegisterKeyMapping)
local RegisterCommand = assert(RegisterCommand)
local SendNUIMessage = assert(SendNUIMessage)
local RegisterNUICallback = assert(RegisterNUICallback)
local IsScreenFadedOut = assert(IsScreenFadedOut)
local IsPauseMenuActive = assert(IsPauseMenuActive)
local CreateThread = assert(Citizen.CreateThread)
local Wait = assert(Citizen.Wait)
local exports = assert(exports)

--- MenuV globals
---@type Utilities
local Utilities = assert(Utilities)

local MenuV = setmetatable({
    ---@type string
    __class = 'MenuV',
    ---@type string
    __type = 'MenuV',
    ---@type boolean
    Loaded = false,
    ---@type string
    Language = Utilities:Ensure((Config or {}).Language, 'en'),
    ---@type number
    ThreadWait = Utilities:Ensure((Config or {}).HideInterval, 250),
    ---@type table<string, string>
    Translations = {},
    ---@class keys
    Keys = setmetatable({ data = {}, __class = 'MenuVKeys', __type = 'keys' }, {
        __index = function(t, k)
            return rawget(t.data, k)
        end,
        __newindex = function(t, k, v)
            k = Utilities:Ensure(k, 'unknown')

            if (k == 'unknown') then return end

            local rawKey = rawget(t.data, k)
            local keyExists = rawKey ~= nil
            local prevState = Utilities:Ensure((rawKey or {}).status, false)
            local newState = Utilities:Ensure(v, false)

            if (keyExists) then
                rawset(t.data[k], 'status', newState)

                if (prevState ~= newState) then
                    local action = newState and not prevState and 'KEY_PRESSED' or 'KEY_RELEASED'
                    local key = Utilities:Ensure(rawKey.action, 'UNKNOWN')

                    SendNUIMessage({ action = action, key = key })
                end
            end
        end,
        __call = function(t, k, a)
            k = Utilities:Ensure(k, 'unknown')
            a = Utilities:Ensure(a, 'UNKNOWN')

            if (k == 'unknown') then return end

            local rawKey = rawget(t.data, k)
            local keyExists = rawKey ~= nil

            if (keyExists) then return end

            rawset(t.data, k, { status = false, action = a })
        end
    })
}, {})

--- Load all translations
local translations_path = ('languages/%s.json'):format(MenuV.Language)
local translations_raw = LoadResourceFile('menuv', translations_path)

if (translations_raw) then
    local transFile = decode(translations_raw)

    if (transFile) then MenuV.Translations = Utilities:Ensure(transFile.translations, {}) end
end

--- Register a `action` with custom keybind
---@param action string Action like: UP, DOWN, LEFT...
---@param description string Description of keybind
---@param defaultType string Type like: keyboard, mouse etc.
---@param defaultKey string Default key for this keybind
function MenuV:RegisterKey(action, description, defaultType, defaultKey)
    action = Utilities:Ensure(action, 'UNKNOWN')
    description = Utilities:Ensure(description, 'unknown')
    defaultType = Utilities:Ensure(defaultType, 'keyboard')
    defaultKey = Utilities:Ensure(defaultKey, 'F12')

    action = Utilities:Replace(action, ' ', '_')
    action = upper(action)

    if (self.Keys[action] ~= nil) then return end

    self.Keys(action, action)

    local k = lower(('menuv_%s'):format(action))

    RegisterKeyMapping(('+%s'):format(k), description, defaultType, defaultKey)
    RegisterCommand(('+%s'):format(k), function() MenuV.Keys[action] = true end)
    RegisterCommand(('-%s'):format(k), function() MenuV.Keys[action] = false end)
end

--- Load translation
---@param k string Translation key
---@return string Translation or 'MISSING TRANSLATION'
local function T(k)
    k = Utilities:Ensure(k, 'unknown')

    return Utilities:Ensure(MenuV.Translations[k], 'MISSING TRANSLATION')
end

RegisterNUICallback('loaded', function(_, cb)
    MenuV.Loaded = true
    cb('ok')
end)

--- Trigger the NUICallback for the right resource
---@param name string Name of callback
---@param info table Info returns from callback
---@param cb function Trigger this when callback is done
local function TriggerResourceCallback(name, info, cb)
    local r = Utilities:Ensure(info.r, 'menuv')

    if (r == 'menuv') then cb('ok') return end

    local resource = exports[r] or nil

    if (resource == nil) then cb('ok') return end

    local nuiCallback = resource['NUICallback'] or nil

    if (nuiCallback == nil) then cb('ok') return end

    exports[r]:NUICallback(name, info, cb)
end

RegisterNUICallback('submit', function(info, cb) TriggerResourceCallback('submit', info, cb) end)
RegisterNUICallback('close', function(info, cb) TriggerResourceCallback('close', info, cb) end)
RegisterNUICallback('switch', function(info, cb) TriggerResourceCallback('switch', info, cb) end)
RegisterNUICallback('update', function(info, cb) TriggerResourceCallback('update', info, cb) end)
RegisterNUICallback('open', function(info, cb) TriggerResourceCallback('open', info, cb) end)

--- MenuV exports
exports('IsLoaded', function(cb)
    cb = Utilities:Ensure(cb, function() end)

    if (MenuV.Loaded) then
        cb()
        return
    end

    CreateThread(function()
        local callback = cb

        repeat Wait(0) until MenuV.Loaded

        callback()
    end)
end)

exports('SendNUIMessage', function(input)
    local r = Utilities:Ensure(GetInvokingResource(), 'menuv')

    if (Utilities:Typeof(input) == 'table') then
        if (input.menu) then
            rawset(input.menu, 'resource', r)
        end

        SendNUIMessage(input)
    end
end)

--- Register `MenuV` keybinds
MenuV:RegisterKey('UP', T('keybind_key_up'), 'KEYBOARD', 'UP')
MenuV:RegisterKey('DOWN', T('keybind_key_down'), 'KEYBOARD', 'DOWN')
MenuV:RegisterKey('LEFT', T('keybind_key_left'), 'KEYBOARD', 'LEFT')
MenuV:RegisterKey('RIGHT', T('keybind_key_right'), 'KEYBOARD', 'RIGHT')
MenuV:RegisterKey('ENTER', T('keybind_key_enter'), 'KEYBOARD', 'RETURN')
MenuV:RegisterKey('CLOSE', T('keybind_key_close'), 'KEYBOARD', 'BACK')

--- Hide menu when screen is faded out or pause menu ia active
CreateThread(function()
    local prev_state = false

    while true do
        repeat Wait(0) until MenuV.Loaded

        local new_state = IsScreenFadedOut() or IsPauseMenuActive()

        if (prev_state ~= new_state) then
            SendNUIMessage({ action = 'UPDATE_STATUS', status = not new_state })
        end

        prev_state = new_state

        Wait(MenuV.ThreadWait)
    end
end)