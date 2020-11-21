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
---@type MenuV
local MenuV = assert(MenuV)
---@type Utilities
local U = assert(Utilities)

--- MenuV Menu
---@type Menu
local menu = MenuV:CreateMenu('MenuV', 'Welcome to MenuV', 'topleft', 0, 0, 255)

local button = menu:AddButton({ icon = '😃', label = 'Test', value = menu, description = 'YEA :D' })
local confirm = menu:AddConfirm({ icon = '🔥', label = 'Confirm', value = 'yes' })
local range = menu:AddRange({ icon = '⚽', label = 'Range Item', min = 0, max = 10, value = 0 })
local checkbox = menu:AddCheckbox({ icon = '💡', label = 'Checkbox Item', value = 'n' })
local slider = menu:AddSlider({ icon = '❤️', label = 'Slider', value = 'demo', values = {
    { label = 'Demo Item', value = 'demo', description = 'Demo Item 1' },
    { label = 'Demo Item 2', value = 'demo2', description = 'Demo Item 2' },
    { label = 'Demo Item 3', value = 'demo3', description = 'Demo Item 3' },
    { label = 'Demo Item 4', value = 'demo4', description = 'Demo Item 4' }
}})

menu()