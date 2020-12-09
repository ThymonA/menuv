# MenuV | Standalone Menu for FiveM | NUI Menu
[![N|CoreV](https://i.imgur.com/iq1llQG.jpg)](https://github.com/ThymonA/menuv)

[![Issues](https://img.shields.io/github/issues/ThymonA/menuv.svg?style=for-the-badge)](https://github.com/ThymonA/menuv/issues)
[![License](https://img.shields.io/github/license/ThymonA/menuv.svg?style=for-the-badge)](https://github.com/ThymonA/menuv/blob/master/LICENSE)
[![Forks](https://img.shields.io/github/forks/ThymonA/menuv.svg?style=for-the-badge)](https://github.com/ThymonA/menuv)
[![Stars](https://img.shields.io/github/stars/ThymonA/menuv.svg?style=for-the-badge)](https://github.com/ThymonA/menuv)

---

**[MenuV](https://github.com/ThymonA/menuv)** is a library written for **[FiveM](https://fivem.net/)** and only uses NUI functionalities. This library allows you to create menus in **[FiveM](https://fivem.net/)**. This project is open-source and you must respect the [license](https://github.com/ThymonA/menuv/blob/master/LICENSE) and the hard work.

## Features
- Support for simple buttons, sliders, checkboxes, lists and confirms
- Support for emojis on items
- Support for custom colors (RGB)
- Support for all screen resolutions.
- Item descriptions
- Rebindable keys
- Event-based callbacks
- Uses `2 msec` while menu open and idle.
- Documentation on [menuv.fivem.io/api/](https://menuv.fivem.io/api/)
- Themes: **[default](https://i.imgur.com/KSkeiQm.png)** or **[native](https://i.imgur.com/KSkeiQm.png)**

## Compile files
**[MenuV](https://github.com/ThymonA/menuv)** uses [VueJS 2.6.11 or newer](https://vuejs.org/v2/guide/installation.html#NPM) and [TypeScript 3.8.3 or newer](https://www.npmjs.com/package/typescript) with [NodeJS Package Manager](https://nodejs.org/en/). You need to have [NPM a.k.a NodeJS Package Manager](https://nodejs.org/en/download/) installed on your system in order to compile **[MenuV](https://github.com/ThymonA/menuv)** files.

First download all dependencies by doing
```powershell
npm install
```
After you have downloaded/loaded all dependencies, you can compile **[MenuV](https://github.com/ThymonA/menuv)** files by doeing.
```powershell
npx webpack
```
After the command is executed you will see a `dist` folder containing all the **NUI** files needed for **[MenuV](https://github.com/ThymonA/menuv)**.

**When downloading a [release](https://github.com/ThymonA/menuv/releases), this step is not necessary.** Files are already compiled.

## How to use?
1. Add `start menuv` to your **server.cfg** before the resources that's uses **menuv**
2. To use **[MenuV](https://github.com/ThymonA/menuv)** you must add **@menuv/menuv.lua** in your **fxmanifest.lua** file.

   ```lua
   client_scripts {
      '@menuv/menuv.lua',
      'example.lua'
   }
   ```

### Create a menu
Create a menu by calling the **MenuV:CreateMenu** function.
```ts
MenuV:CreateMenu(title: string, subtitle: string, position: string, red: number, green: number, blue: number, texture: string, disctionary: string, namespace: string, theme: string)
```
**Example:**
```lua
local menu = MenuV:CreateMenu('MenuV', 'Welcome to MenuV', 'topleft', 255, 0, 0, 'size-125', 'default', 'menuv', 'example_namespace', 'native')
```

### Create menu items
Create a item by calling **AddButton**, **AddConfirm**, **AddRange**, **AddCheckbox** or **AddSlider** in the created menu
```ts
/** CREATE A BUTTON */
menu:AddButton({ icon: string, label: string, description: string, value: any, disabled: boolean });

/** CREATE A CONFIRM */
menu:AddConfirm({ icon: string, label: string, description: string, value: boolean, disabled: boolean });

/** CREATE A RANGE */
menu:AddRange({ icon: string, label: string, description: string, value: number, min: number, max: number, disabled: boolean });

/** CREATE A CHECKBOX */
menu:AddCheckbox({ icon: string, label: string, description: string, value: boolean, disabled: boolean });

/** CREATE A SLIDER */
menu:AddSlider({ icon: string, label: string, description: string, value: number, values: [] { label: string, value: any, description: string }, disabled: boolean });
```
To see example in practice, see [example.lua](https://github.com/ThymonA/menuv/blob/master/example.lua)

### Events
In **[MenuV](https://github.com/ThymonA/menuv)** you can register event-based callbacks on menu and/or items.
```ts
/** REGISTER A EVENT ON MENU */
menu:On(event: string, callback: function);

/** REGISTER A EVENT ON ANY ITEM */
item:On(event: string, callback: function);
```

## Documentation
Read **[MenuV documentation](https://menuv.fivem.io/api/)**

## License
Project is written by **[ThymonA](https://github.com/ThymonA/)** and published under
**GNU General Public License v3.0**
[Read License](https://github.com/ThymonA/menuv/blob/master/LICENSE)

## Screenshot
**How is this menu made?** see **[example.lua](https://github.com/ThymonA/menuv/blob/master/example.lua)**


Default | Native
:-------|:--------
![MenuV Default](https://i.imgur.com/xGagIBm.png) | ![MenuV Native](https://i.imgur.com/KSkeiQm.png)
[Default Theme](https://i.imgur.com/KSkeiQm.png) | [Native Theme](https://i.imgur.com/KSkeiQm.png)