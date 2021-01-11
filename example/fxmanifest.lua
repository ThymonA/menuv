----------------------- [ MenuV ] -----------------------
-- GitHub: https://github.com/ThymonA/menuv/
-- License: GNU General Public License v3.0
--          https://choosealicense.com/licenses/gpl-3.0/
-- Author: Thymon Arens <contact@arens.io>
-- Name: MenuV
-- Version: 1.0.0
-- Description: FiveM menu libarary for creating menu's
----------------------- [ MenuV ] -----------------------

fx_version 'cerulean'
game 'gta5'

name 'MenuV'
version '1.0.0'
description 'FiveM menu libarary for creating menu\'s'
author 'ThymonA'
contact 'contact@arens.io'
url 'https://github.com/ThymonA/menuv/'

client_scripts {
    '@menuv/menuv.lua',
    'example.lua'
}

dependencies {
    'menuv'
}