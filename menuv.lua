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
local pcall = assert(pcall)
local insert = assert(table.insert)
local upper = assert(string.upper)
local setmetatable = assert(setmetatable)

--- FiveM globals
local Wait = assert(Citizen.Wait)
local CreateThread = assert(Citizen.CreateThread)
local GetResourceState = assert(GetResourceState)
local GetCurrentResourceName = assert(GetCurrentResourceName)
local exports = assert(exports)

--- MenuV
---@class MenuV
local MenuV_T = {
    __class = 'MenuV',
    __type = 'MenuV',
    __funcs = {
        open = { loaded = false, self = nil, func = nil }
    },
    currentResource = GetCurrentResourceName(),
    menus = {}
}
local MenuV_MT = {}
local MenuV = setmetatable(MenuV_T, MenuV_MT)

--- Create a `MenuV` menu
---@param title string Title of Menu
---@param subtitle string Subtitle of Menu
---@param position string Position of Menu
---@param r number 0-255 RED
---@param g number 0-255 GREEN
---@param b number 0-255 BLUE
---@return Menu
function MenuV:CreateMenu(title, subtitle, position, r, g, b)
    local m = CreateMenu({
        Title = title,
        Subtitle = subtitle,
        Position = position,
        R = r,
        G = g,
        B = b
    })

    insert(self.menus, m)

    return self.menus[#self.menus] or m
end

--- Open a menu
--- @param input Menu|string Menu to open
function MenuV:OpenMenu(input)
    if (U:Typeof(input) == 'string') then
        for i = 1, #self.menus, 1 do
            if (self.menus[i].UUID == input) then
                local menu = self.menus[i]

                if (self.__funcs.open.loaded) then
                    if (self.__funcs.open.self == nil) then
                        self.__funcs.open.func(menu)
                    else
                        self.__funcs.open.func(self.__funcs.open.self, menu)
                    end
                else
                    CreateThread(function()
                        while not self.__funcs.open.loaded do Wait(0) end

                        MenuV:OpenMenu(menu)
                    end)
                end
            end
        end
        return
    end

    if (U:Typeof(input) == 'Menu') then
        local menu = input

        if (self.__funcs.open.loaded) then
            if (self.__funcs.open.self == nil) then
                self.__funcs.open.func(menu)
            else
                self.__funcs.open.func(self.__funcs.open.self, menu)
            end
        else
            CreateThread(function()
                while not self.__funcs.open.loaded do Wait(0) end

                MenuV:OpenMenu(menu)
            end)
        end
    end
end

--- Try to execute `func`, if error has been throwed `catch_func` is called
---@param func function Try to execute this function
---@param catch_func function Catch when `func` has failed to execute
local function try(func, catch_func)
    if (U:Typeof(func) ~= 'function') then return end
    if (U:Typeof(catch_func) ~= 'function') then return end

    local ok, exp = pcall(func)

    if (not ok) then
        catch_func(exp)
    end
end

local function load_export(_le)
    CreateThread(function()
        if (MenuV.currentResource == 'menuv') then
            local loaded = _G.MENUV_LOADED or _ENV.MENUV_LOADED

            if (not loaded) then
                Wait(0)
                load_export(_le)

                return
            end
        else
            repeat Wait(0) until GetResourceState(_le.r) == 'started'
        end

        try(function()
            if (MenuV.currentResource ~= _le.r) then
                MenuV.__funcs[_le.f] = { loaded = false, self = assert(exports[_le.r]), func = nil }
                MenuV.__funcs[_le.f].func = assert(MenuV.__funcs[_le.f].self[_le.f])
                MenuV.__funcs[_le.f].loaded = true
            else
                local KEY = ('MENUV_%s'):format(upper(_le.f))

                MenuV.__funcs[_le.f] = { loaded = true, self = nil, func = assert(_G[KEY] or _ENV[KEY]) }
            end
        end, function()
            MenuV.__funcs[_le.f] = { loaded = true, self = nil, func = function() end }
        end)
    end)
end

--- Load and cache those exprots
local __loadExports = {
    [1] = { r = 'menuv', f = 'open' }
}

for _, _le in pairs(__loadExports) do
    try(function()
        if (MenuV.currentResource ~= _le.r) then
            MenuV.__funcs[_le.f] = { loaded = false, self = assert(exports[_le.r]), func = nil }
            MenuV.__funcs[_le.f].func = assert(MenuV.__funcs[_le.f].self[_le.f])
            MenuV.__funcs[_le.f].loaded = true
        else
            MenuV.__funcs[_le.f] = { loaded = true, self = nil, func = assert(_G[('MENUV_%s'):format(upper(_le.f))] or _ENV[('MENUV_%s'):format(upper(_le.f))]) }
        end
    end, function()
        MenuV.__funcs[_le.f] = { loaded = false, self = nil, func = nil }

        load_export(_le)
    end)
end

--- Make `MenuV` global accessible
_G.MenuV = MenuV
_ENV.MenuV = MenuV