--- MenuV Menu
---@type Menu
local menu = MenuV:CreateMenu(false, 'Welcome to MenuV', 'topleft', 255, 0, 0, 'size-125', 'example', 'menuv', 'example_namespace')
local menu2 = MenuV:CreateMenu('Demo 2', 'Open this demo menu in MenuV', 'topleft', 255, 0, 0)

local menu_button = menu:AddButton({ icon = '😃', label = 'Open Demo 2 Menu', value = menu2, description = 'YEA :D from first menu' })
local menu2_button = menu2:AddButton({ icon = '😃', label = 'Open First Menu', value = menu, description = 'YEA :D from second menu' })
local confirm = menu:AddConfirm({ icon = '🔥', label = 'Confirm', value = 'no' })
local range = menu:AddRange({ icon = '⚽', label = 'Range Item', min = 0, max = 10, value = 0, saveOnUpdate = true })
local checkbox = menu:AddCheckbox({ icon = '💡', label = 'Checkbox Item', value = 'n' })
local checkbox_disabled = menu:AddCheckbox({ icon = '💡', label = 'Checkbox Disabled', value = 'n', disabled = true })
local slider = menu:AddSlider({ icon = '❤️', label = 'Slider', value = 'demo', values = {
    { label = 'Demo Item', value = 'demo', description = 'Demo Item 1' },
    { label = 'Demo Item 2', value = 'demo2', description = 'Demo Item 2' },
    { label = 'Demo Item 3', value = 'demo3', description = 'Demo Item 3' },
    { label = 'Demo Item 4', value = 'demo4', description = 'Demo Item 4' }
}})

--- Events
confirm:On('confirm', function(item) print('YOU ACCEPTED THE TERMS') end)
confirm:On('deny', function(item) print('YOU DENIED THE TERMS') end)

range:On('select', function(item, value) print(('FROM %s to %s YOU SELECTED %s'):format(item.Min, item.Max, value)) end)
range:On('change', function(item, newValue, oldValue)
    menu.Title = ('MenuV %s'):format(newValue)
end)

slider:On('select', function(item, value) print(('YOU SELECTED %s'):format(value)) end)

confirm:On('enter', function(item) print('YOU HAVE NOW A CONFIRM ACTIVE') end)
confirm:On('leave', function(item) print('YOU LEFT OUR CONFIRM :(') end)

menu:On('switch', function(item, currentItem, prevItem) print(('YOU HAVE SWITCH THE ITEMS FROM %s TO %s'):format(prevItem.__type, currentItem.__type)) end)

menu2:On('open', function(m)
    m:ClearItems()

    for i = 1, 10, 1 do
        math.randomseed(GetGameTimer() + i)

        m:AddButton({ ignoreUpdate = i ~= 10, icon = '❤️', label = ('Open Menu %s'):format(math.random(0, 1000)), value = menu, description = ('YEA! ANOTHER RANDOM NUMBER: %s'):format(math.random(0, 1000)), select = function(i) print('YOU CLICKED ON THIS ITEM!!!!') end })
    end
end)

menu:OpenWith('KEYBOARD', 'F1') -- Press F1 to open Menu