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
local type = assert(type)
local load = assert(load)
local xpcall = assert(xpcall)
local pairs = assert(pairs)
local insert = assert(table.insert)
local remove = assert(table.remove)
local traceback = assert(debug.traceback)
local setmetatable = assert(setmetatable)
local __environment = assert(_ENV)

--- FiveM globals
local LOAD_RESOURCE_FILE = assert(LoadResourceFile)
local GET_CURRENT_RESOURCE_NAME = assert(GetCurrentResourceName)
local HAS_STREAMED_TEXTURE_DICT_LOADED = assert(HasStreamedTextureDictLoaded)
local REQUEST_STREAMED_TEXTURE_DICT = assert(RequestStreamedTextureDict)
local CreateThread = assert(Citizen.CreateThread)
local Wait = assert(Citizen.Wait)

--- Load a file from `menuv`
---@param path string Path in `menuv`
---@return any|nil Results of nil
local function load_file(path)
    if (path == nil or type(path) ~= 'string') then return nil end

    local raw_file = LOAD_RESOURCE_FILE('menuv', path)

    if (raw_file) then
        local raw_func, _ = load(raw_file, ('menuv/%s'):format(path), 't', __environment)

        if (raw_func) then
            local ok, result = xpcall(raw_func, traceback)

            if (ok) then
                return result
            end
        end
    end

    return nil
end

--- MenuV globals
Utilities = assert(Utilities or load_file('app/lua_components/utilities.lua'))
CreateMenuItem = assert(CreateMenuItem or load_file('app/lua_components/item.lua'))
CreateMenu = assert(CreateMenu or load_file('app/lua_components/menu.lua'))

--- MenuV table
local menuv_table = {
    ---@type string
    __class = 'MenuV',
    ---@type string
    __type = 'MenuV',
    ---@type Menu|nil
    CurrentMenu = nil,
    ---@type string|nil
    CurrentUpdateUUID = nil,
    ---@type string
    CurrentResourceName = GET_CURRENT_RESOURCE_NAME(),
    ---@type boolean
    Loaded = false,
    ---@type Menu[]
    Menus = {},
    ---@type Menu[]
    ParentMenus = {},
    ---@type table<string, function>
    NUICallbacks = {}
}

---@class MenuV
MenuV = setmetatable(menuv_table, {})

--- Send a NUI message to MenuV resource
---@param input any
local SEND_NUI_MESSAGE = function(input)
    exports['menuv']:SendNUIMessage(input)
end

--- Register a NUI callback event
---@param name string Name of callback
---@param cb function Callback to execute
local REGISTER_NUI_CALLBACK = function(name, cb)
    name = Utilities:Ensure(name, 'unknown')
    cb = Utilities:Ensure(cb, function(_, cb) cb('ok') end)

    MenuV.NUICallbacks[name] = cb
end

--- Create a `MenuV` menu
---@param title string Title of Menu
---@param subtitle string Subtitle of Menu
---@param position string Position of Menu
---@param r number 0-255 RED
---@param g number 0-255 GREEN
---@param b number 0-255 BLUE
---@param size string | "'size-100'" | "'size-110'" | "'size-125'" | "'size-150'" | "'size-175'" | "'size-200'"
---@param texture string Name of texture example: "default"
---@param dictionary string Name of dictionary example: "menuv"
---@return Menu
function MenuV:CreateMenu(title, subtitle, position, r, g, b, size, texture, dictionary)
    local menu = CreateMenu({
        Title = title,
        Subtitle = subtitle,
        Position = position,
        R = r,
        G = g,
        B = b,
        Size = size,
        Texture = texture,
        Dictionary = dictionary
    })

    local index = #(self.Menus or {}) + 1

    insert(self.Menus, index, menu)

    return self.Menus[index] or menu
end

--- Load a menu based on `uuid`
---@param uuid string UUID of menu
---@return Menu|nil Founded menu or `nil`
function MenuV:GetMenu(uuid)
    uuid = Utilities:Ensure(uuid, '00000000-0000-0000-0000-000000000000')

    for _, v in pairs(self.Menus) do
        if (v.UUID == uuid) then
            return v
        end
    end

    return nil
end

--- Open a menu
---@param menu Menu|string Menu or UUID of Menu
---@param cb function Execute this callback when menu has opened
function MenuV:OpenMenu(menu, cb)
    local uuid = Utilities:Typeof(menu) == 'Menu' and menu.UUID or Utilities:Typeof(menu) == 'string' and menu

    if (uuid == nil) then return end

    cb = Utilities:Ensure(cb, function() end)

    menu = self:GetMenu(uuid)

    if (menu == nil) then return end

    local dictionaryLoaded = HAS_STREAMED_TEXTURE_DICT_LOADED(menu.Dictionary)

    if (not self.Loaded or not dictionaryLoaded) then
        if (not dictionaryLoaded) then REQUEST_STREAMED_TEXTURE_DICT(menu.Dictionary) end

        CreateThread(function()
            repeat Wait(0) until MenuV.Loaded

            if (not dictionaryLoaded) then
                repeat Wait(10) until HAS_STREAMED_TEXTURE_DICT_LOADED(menu.Dictionary)
            end

            MenuV:OpenMenu(uuid, cb)
        end)
        return
    end

    if (self.CurrentMenu ~= nil) then
        insert(self.ParentMenus, self.CurrentMenu)

        self.CurrentMenu:RemoveOnEvent('update', self.CurrentUpdateUUID)
        self.CurrentMenu:DestroyThreads()
    end

    self.CurrentMenu = menu
    self.CurrentUpdateUUID = menu:On('update', function(m, k, v)
        k = Utilities:Ensure(k, 'unknown')

        if (k == 'Title' or k == 'title') then
            SEND_NUI_MESSAGE({ action = 'UPDATE_TITLE', title = Utilities:Ensure(v, 'MenuV'), __uuid = m.UUID })
        elseif (k == 'Subtitle' or k == 'subtitle') then
            SEND_NUI_MESSAGE({ action = 'UPDATE_SUBTITLE', subtitle = Utilities:Ensure(v, ''), __uuid = m.UUID })
        elseif (k == 'Items' or k == 'items') then
            SEND_NUI_MESSAGE({ action = 'UPDATE_ITEMS', items = (m.Items:ToTable() or {}), __uuid = m.UUID })
        elseif (k == 'Item' or k == 'item' and Utilities:Typeof(v) == 'Item') then
            SEND_NUI_MESSAGE({ action = 'UPDATE_ITEM', item = m.Items:ItemToTable(v) or {}, __uuid = m.UUID })
        elseif (k == 'AddItem' or k == 'additem' and Utilities:Typeof(v) == 'Item') then
            SEND_NUI_MESSAGE({ action = 'ADD_ITEM', item = m.Items:ItemToTable(v), __uuid = m.UUID })
        elseif (k == 'RemoveItem' or k == 'removeitem' and Utilities:Typeof(v) == 'Item') then
            SEND_NUI_MESSAGE({ action = 'REMOVE_ITEM', uuid = v.UUID, __uuid = m.UUID })
        elseif (k == 'UpdateItem' or k == 'updateitem' and Utilities:Typeof(v) == 'Item') then
            SEND_NUI_MESSAGE({ action = 'UPDATE_ITEM', item = m.Items:ItemToTable(v) or {}, __uuid = m.UUID })
        end
    end)

    SEND_NUI_MESSAGE({
        action = 'OPEN_MENU',
        menu = menu:ToTable()
    })

    cb()
end

--- Close a menu
---@param menu Menu|string Menu or UUID of Menu
---@param cb function Execute this callback when menu has is closed or parent menu has opened
function MenuV:CloseMenu(menu, cb)
    local uuid = Utilities:Typeof(menu) == 'Menu' and menu.UUID or Utilities:Typeof(menu) == 'string' and menu

    if (uuid == nil) then cb() return end

    cb = Utilities:Ensure(cb, function() end)

    if (not self.Loaded) then
        CreateThread(function()
            repeat Wait(0) until MenuV.Loaded

            MenuV:CloseMenu(uuid, cb)
        end)
        return
    end

    menu = self:GetMenu(uuid)

    if (menu == nil or self.CurrentMenu == nil or self.CurrentMenu.UUID ~= menu.UUID) then cb() return end

    self.CurrentMenu:RemoveOnEvent('update', self.CurrentUpdateUUID)
    self.CurrentMenu:Trigger('close')
    self.CurrentMenu:DestroyThreads()
    self.CurrentMenu = nil

    if (#self.ParentMenus <= 0) then
        SEND_NUI_MESSAGE({ action = 'CLOSE_MENU', uuid = uuid })
        cb()
        return
    end

    local prev_index = #self.ParentMenus
    local prev_menu = self.ParentMenus[prev_index] or nil

    if (prev_menu == nil) then cb() return end

    remove(self.ParentMenus, prev_index)

    self:OpenMenu(prev_menu, cb)
end

--- Close all menus
---@param cb function Execute this callback when all menus are closed
function MenuV:CloseAll(cb)
    cb = Utilities:Ensure(cb, function() end)

    if (not self.Loaded) then
        CreateThread(function()
            repeat Wait(0) until MenuV.Loaded

            MenuV:CloseAll(cb)
        end)
        return
    end

    if (self.CurrentMenu == nil) then cb() return end

    local uuid = Utilities:Ensure(self.CurrentMenu.UUID, '00000000-0000-0000-0000-000000000000')

    self.CurrentMenu:RemoveOnEvent('update', self.CurrentUpdateUUID)
    self.CurrentMenu:Trigger('close')
    self.CurrentMenu:DestroyThreads()

    SEND_NUI_MESSAGE({ action = 'CLOSE_MENU', uuid = uuid })

    self.CurrentMenu = nil
    self.ParentMenus = {}

    cb()
end

--- Mark MenuV as loaded when `main` resource is loaded
exports['menuv']:IsLoaded(function()
    MenuV.Loaded = true
end)

--- Register callback handler for MenuV
exports('NUICallback', function(name, info, cb)
    name = Utilities:Ensure(name, 'unknown')

    if (MenuV.NUICallbacks == nil or MenuV.NUICallbacks[name] == nil) then
        return
    end

    MenuV.NUICallbacks[name](info, cb)
end)

REGISTER_NUI_CALLBACK('open', function(info, cb)
    local uuid = Utilities:Ensure(info.uuid, '00000000-0000-0000-0000-000000000000')

    cb('ok')

    if (MenuV.CurrentMenu == nil or MenuV.CurrentMenu.UUID == uuid) then return end

    for _, v in pairs(MenuV.ParentMenus) do
        if (v.UUID == uuid) then
            return
        end
    end

    MenuV.CurrentMenu:RemoveOnEvent('update', MenuV.CurrentUpdateUUID)
    MenuV.CurrentMenu:Trigger('close')
    MenuV.CurrentMenu:DestroyThreads()
    MenuV.CurrentMenu = nil
    MenuV.ParentMenus = {}
end)

REGISTER_NUI_CALLBACK('opened', function(info, cb)
    local uuid = Utilities:Ensure(info.uuid, '00000000-0000-0000-0000-000000000000')

    cb('ok')

    if (MenuV.CurrentMenu == nil or MenuV.CurrentMenu.UUID ~= uuid) then return end

    MenuV.CurrentMenu:Trigger('open')
end)

REGISTER_NUI_CALLBACK('submit', function(info, cb)
    local uuid = Utilities:Ensure(info.uuid, '00000000-0000-0000-0000-000000000000')

    cb('ok')

    if (MenuV.CurrentMenu == nil) then return end

    for k, v in pairs(MenuV.CurrentMenu.Items) do
        if (v.UUID == uuid) then
            if (v.__type == 'confirm' or v.__type == 'checkbox') then
                v.Value = Utilities:Ensure(info.value, false)
            elseif (v.__type == 'range') then
                v.Value = Utilities:Ensure(info.value, v.Min)
            elseif (v.__type == 'slider') then
                v.Value = Utilities:Ensure(info.value, 0) + 1
            end

            MenuV.CurrentMenu:Trigger('select', v)

            if (v.__type == 'button' or v.__type == 'menu') then
                MenuV.CurrentMenu.Items[k]:Trigger('select')
            elseif (v.__type == 'range') then
                MenuV.CurrentMenu.Items[k]:Trigger('select', v.Value)
            elseif (v.__type == 'slider') then
                local option = MenuV.CurrentMenu.Items[k].Values[v.Value] or nil

                if (option == nil) then return end

                MenuV.CurrentMenu.Items[k]:Trigger('select', option.Value)
            end

            return
        end
    end
end)

REGISTER_NUI_CALLBACK('close', function(info, cb)
    local uuid = Utilities:Ensure(info.uuid, '00000000-0000-0000-0000-000000000000')

    if (MenuV.CurrentMenu == nil or MenuV.CurrentMenu.UUID ~= uuid) then cb('ok') return end

    MenuV.CurrentMenu:RemoveOnEvent('update', MenuV.CurrentUpdateUUID)
    MenuV.CurrentMenu:Trigger('close')
    MenuV.CurrentMenu:DestroyThreads()
    MenuV.CurrentMenu = nil

    if (#MenuV.ParentMenus <= 0) then cb('ok') return end

    local prev_index = #MenuV.ParentMenus
    local prev_menu = MenuV.ParentMenus[prev_index] or nil

    if (prev_menu == nil) then cb('ok') return end

    remove(MenuV.ParentMenus, prev_index)

    MenuV:OpenMenu(prev_menu, function()
        cb('ok')
    end)
end)

REGISTER_NUI_CALLBACK('switch', function(info, cb)
    local prev_uuid = Utilities:Ensure(info.prev, '00000000-0000-0000-0000-000000000000')
    local next_uuid = Utilities:Ensure(info.next, '00000000-0000-0000-0000-000000000000')
    local prev_item, next_item = nil, nil

    cb('ok')

    if (MenuV.CurrentMenu == nil) then return end

    for k, v in pairs(MenuV.CurrentMenu.Items) do
        if (v.UUID == prev_uuid) then
            prev_item = v

            MenuV.CurrentMenu.Items[k]:Trigger('leave')
        end

        if (v.UUID == next_uuid) then
            next_item = v

            MenuV.CurrentMenu.Items[k]:Trigger('enter')
        end
    end

    if (prev_item ~= nil and next_item ~= nil) then
        MenuV.CurrentMenu:Trigger('switch', next_item, prev_item)
    end
end)

REGISTER_NUI_CALLBACK('update', function(info, cb)
    local uuid = Utilities:Ensure(info.uuid, '00000000-0000-0000-0000-000000000000')

    cb('ok')

    if (MenuV.CurrentMenu == nil) then return end

    for k, v in pairs(MenuV.CurrentMenu.Items) do
        if (v.UUID == uuid) then
            local newValue, oldValue = nil, nil

            if (v.__type == 'confirm' or v.__type == 'checkbox') then
                newValue = Utilities:Ensure(info.now, false)
                oldValue = Utilities:Ensure(info.prev, false)
            elseif (v.__type == 'range') then
                newValue = Utilities:Ensure(info.now, v.Min)
                oldValue = Utilities:Ensure(info.prev, v.Min)
            elseif (v.__type == 'slider') then
                newValue = Utilities:Ensure(info.now, 0) + 1
                oldValue = Utilities:Ensure(info.prev, 0) + 1
            end

            if (Utilities:Any(v.__type, { 'button', 'menu', 'label' }, 'value')) then return end

            MenuV.CurrentMenu:Trigger('update', v, newValue, oldValue)
            MenuV.CurrentMenu.Items[k]:Trigger('change', newValue, oldValue)

            if (v.SaveOnUpdate) then
                MenuV.CurrentMenu.Items[k].Value = newValue

                if (v.__type == 'range') then
                    MenuV.CurrentMenu.Items[k]:Trigger('select', v.Value)
                elseif (v.__type == 'slider') then
                    local option = MenuV.CurrentMenu.Items[k].Values[v.Value] or nil

                    if (option == nil) then return end

                    MenuV.CurrentMenu.Items[k]:Trigger('select', option.Value)
                end
            end
            return
        end
    end
end)