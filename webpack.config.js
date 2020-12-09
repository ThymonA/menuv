/**
----------------------- [ MenuV ] -----------------------
-- GitHub: https://github.com/ThymonA/menuv/
-- License: GNU General Public License v3.0
--          https://choosealicense.com/licenses/gpl-3.0/
-- Author: Thymon Arens <contact@arens.io>
-- Name: MenuV
-- Version: 1.0.0
-- Description: FiveM menu library for creating menu's
----------------------- [ MenuV ] -----------------------
*/
const HTML_WEBPACK_PLUGIN = require('html-webpack-plugin');
const HTML_WEBPACK_INLINE_SOURCE_PLUGIN = require('html-webpack-inline-source-plugin');
const VUE_LOADER_PLUGIN = require('vue-loader/lib/plugin');
const COPY_PLUGIN = require('copy-webpack-plugin');

module.exports = {
    mode: 'production',
    entry: './app/load.ts',
    module: {
        rules: [
            {
                test: /\.ts$/,
                loader: 'ts-loader',
                exclude: /node_modules/,
                options: { appendTsSuffixTo: [/\.vue$/] }
            },
            {
                test: /\.vue$/,
                loader: 'vue-loader'
            }
        ]
    },
    plugins: [
        new VUE_LOADER_PLUGIN(),
        new HTML_WEBPACK_PLUGIN({
            inlineSource: '.(js|css)$',
            template: './app/html/menuv.html',
            filename: 'menuv.html'
        }),
        new HTML_WEBPACK_INLINE_SOURCE_PLUGIN(),
        new COPY_PLUGIN([
            { from: 'app/html/assets/css/main.css', to: 'assets/css/main.css' },
            { from: 'app/html/assets/css/native_theme.css', to: 'assets/css/native_theme.css' },
            { from: 'app/html/assets/fonts/SignPainterHouseScript.woff', to: 'assets/fonts/SignPainterHouseScript.woff' }
        ])
    ],
    resolve: {
        extensions: [ '.ts', '.js' ]
    },
    output: {
        filename: 'menuv.js',
        path: __dirname + '/dist/'
    }
};