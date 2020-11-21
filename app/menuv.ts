/**
----------------------- [ MenuV ] -----------------------
-- GitHub: https://github.com/ThymonA/menuv/
-- License: GNU General Public License v3.0
--          https://choosealicense.com/licenses/gpl-3.0/
-- Author: Thymon Arens <contact@arens.io>
-- Name: MenuV
-- Version: 1.0.0
-- Description: FiveM menu libarary for creating menu's
----------------------- [ MenuV ] -----------------------
*/
import VUE from 'vue';
import STYLE from './component/style';

export interface Option {
    label: string;
    description: string;
    value: number;
}

export interface Item {
    index: number;
    type: string;
    uuid: string;
    icon: string;
    label: string;
    description: string;
    value: any;
    values: Option[];
    min: number;
    max: number;
    disabled: boolean;
}

export interface Menu {
    title: string;
    subtitle: string;
    color: {
        r: number,
        g: number,
        b: number
    },
    items: Item[]
}

export default VUE.extend({
    template: '#menuv_template',
    name: 'menuv',
    components: {
        STYLE
    },
    data() {
        return {
            show: false,
            title: 'MenuV',
            subtitle: '',
            color: {
                r: 0,
                g: 0,
                b: 255
            },
            items: [] as Item[],
            listener: (event: MessageEvent) => {},
            index: 0
        }
    },
    destroyed() {
        window.removeEventListener('message', this.listener)
    },
    mounted() {
        this.listener = (event: MessageEvent) => {
            const data: any = event.data ||(<any>event).detail;
            
            if (!data || !data.action) { return; }

            const typeRef = data.action as 'OPEN_MENU' | 'CLOSE_MENU' | 'UPDATE_TITLE' | 'UPDATE_SUBTITLE' | 'KEY_PRESSED'
        
            if (this[typeRef]) {
                this[typeRef](data);
            }
        };

        window.addEventListener('message', this.listener);

        this.POST('http://menuv/loaded', {});
    },
    watch: {
        title() {},
        subtitle() {},
        color() {},
        options() {},
        index() {}
    },
    computed: {},
    methods: {
        OPEN_MENU({ menu }: { menu: Menu }) {
            this.RESET_MENU();

            this.title = this.ENSURE(menu.title, this.title);
            this.subtitle = this.ENSURE(menu.subtitle, this.subtitle);
            this.color = menu.color || this.color;
            this.items = menu.items || [];
            this.show = true;
        },
        CLOSE_MENU() {
            this.RESET_MENU();      
        },
        UPDATE_TITLE({ title }: { title: string }) {
            this.title = title || this.title;
        },
        UPDATE_SUBTITLE({ subtitle }: { subtitle: string }) {
            this.subtitle = subtitle || this.subtitle;
        },
        ADD_ITEM({ item, index }: { item: Item, index?: number }) {
            if (typeof index == 'undefined' || index == null || index < 0 || index >= this.items.length) {
                this.items.push(item);
            } else {
                this.items.splice(index, 0, item);
            }
        },
        REMOVE_ITEM({ uuid }: { uuid: string }) {
            if (typeof uuid != 'string' || uuid == '') { return }

            for (var i = 0; i < this.items.length; i++) {
                if (this.items[i].uuid == uuid) {
                    this.items.splice(i, 1);
                }
            }
        },
        RESET_MENU() {
            this.show = false;
            this.title = 'MenuV';
            this.subtitle = '';
            this.color.r = 0;
            this.color.g = 0;
            this.color.b = 255;
            this.items = [];
        },
        GET_SLIDER_LABEL({ uuid }: { uuid: string }) {
            for (var i = 0; i < this.items.length; i++) {
                if (this.items[i].uuid == uuid && this.items[i].type == 'slider') {
                    const currentValue = this.items[i].value as number;
                    const values = this.items[i].values;

                    if (values.length == 0) { return ''; }

                    if (currentValue < 0 || currentValue >= values.length) {
                        return values[0].label || 'Unknown';
                    }

                    return values[currentValue].label || 'Unknown';
                }
            }

            return '';
        },
        GET_CURRENT_DESCRIPTION() {
            const index = this.index || 0;

            if (index >= 0 && index < this.items.length) {
                return this.ENSURE(this.items[index].description, '');
            }

            return '';
        },
        ENSURE: function<T>(input: any, output: T): T {
            const inputType = typeof input;
            const outputType = typeof output;

            if (inputType == 'undefined') { return output as T; }

            if (outputType == 'string') {
                if (inputType == 'string') {
                    const isEmpty = input == null || (input as string) == 'nil' || (input as string) == '';

                    if (isEmpty) { return output as T; }

                    return input as T;
                }

                if (inputType == 'number') { return (input as number).toString() as unknown as T || output as T; }
                
                return output as T;
            }

            if (outputType == 'number') {
                if (inputType == 'string') {
                    const isEmpty = input == null || (input as string) == 'nil' || (input as string) == '';

                    if (isEmpty) { return output as T; }

                    return Number(input as string) as unknown as T || output as T;
                }

                if (inputType == 'number') { return input as T; }

                return output as T;
            }

            return output as T;
        },
        IS_DEFAULT: function(input: any): boolean {
            if (typeof input == 'string') {
                return input == null || (input as string) == 'nil' || (input as string) == '';
            }

            if (typeof input == 'number') {
                return (input as number) == 0
            }

            if (typeof input == 'boolean') {
                return (input as boolean) == false
            }

            return false;
        },
        KEY_PRESSED({ key }: { key: string }) {
            const k = key as 'UP' | 'DOWN' | 'LEFT' | 'RIGHT' | 'ENTER' | 'CLOSE'

            if (typeof k == 'undefined' || k == null) {
                return
            }

            const keyRef = `KEY_${k}` as 'KEY_UP' | 'KEY_DOWN' | 'KEY_LEFT' | 'KEY_RIGHT' | 'KEY_ENTER' | 'KEY_CLOSE';

            if (this[keyRef]) {
                this[keyRef]();
            }
        },
        KEY_UP: function() {
            if ((this.index - 1) >= 0) {
                this.index--;
            } else {
                this.index = (this.items.length - 1);
            }
        },
        KEY_DOWN: function() {
            if ((this.index + 1) < this.items.length) {
                this.index++;
            } else {
                this.index = 0;
            }
        },
        KEY_LEFT: function() {

        },
        KEY_RIGHT: function() {

        },
        KEY_ENTER: function() {

        },
        KEY_CLOSE: function() {

        },
        POST: function(url: string, data: object|[]) {
            var request = new XMLHttpRequest();

            request.open('POST', url, true);
            request.open('POST', url, true);
            request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
            request.send(JSON.stringify(data));
        }
    }
});