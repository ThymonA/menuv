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
import STYLE from './vue_components/style';

export interface Option {
    label: string;
    description: string;
    value: number;
}

export interface Item {
    index: number;
    type: 'button' | 'menu' | 'checkbox' | 'confirm' | 'range' | 'slider' | 'label' | 'unknown';
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
    resource: string;
    icon: string;
    uuid: string;
    title: string;
    subtitle: string;
    position: 'topleft' | 'topcenter' | 'topright' | 'centerleft' | 'center' | 'centerright' | 'bottomleft' | 'bottomcenter' | 'bottomright'
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
            resource: 'menuv',
            icon: 'none',
            uuid: '',
            menu: false,
            show: false,
            title: 'MenuV',
            subtitle: '',
            position: 'topleft',
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

            const typeRef = data.action as 'UPDATE_STATUS' | 'OPEN_MENU' | 'CLOSE_MENU' | 'UPDATE_TITLE' | 'UPDATE_SUBTITLE' | 'KEY_PRESSED' | 'RESOURCE_STOPPED'
        
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
        position() {},
        color() {},
        options() {},
        index(newValue, oldValue) {
            const prevItem = this.items[oldValue];
            const currentItem = this.items[newValue];

            this.POST(`http://menuv/switch`, { prev: prevItem.uuid, next: currentItem.uuid, r: this.resource });
        },
        items: {
            deep: true,
            handler(newValue: Item[], oldValue: Item[]) {
                if (this.index >= newValue.length || this.index < 0) { return; }

                let sameItem = null;
                const currentItem = newValue[this.index];

                if (currentItem == null) { return; }

                for (var i = 0; i < oldValue.length; i++) {
                    if (currentItem.uuid == oldValue[i].uuid && currentItem.type == oldValue[i].type) {
                        sameItem = oldValue[i];
                    }
                }

                if (sameItem == null) { return; }
                
                this.POST(`http://menuv/update`, { uuid: currentItem.uuid, prev: sameItem.value, now: currentItem.value, r: this.resource });
            }
        }
    },
    computed: {},
    methods: {
        UPDATE_STATUS({ status }: { status: boolean }) {
            if (this.menu) { this.show = status; }
        },
        OPEN_MENU({ menu }: { menu: Menu }) {
            this.POST(`http://menuv/open`, { uuid: this.uuid, r: this.resource });
            this.RESET_MENU();

            this.index = 0;
            this.resource = this.ENSURE(menu.resource, 'menuv');
            this.icon = this.ENSURE(menu.icon, 'none');
            this.uuid = this.ENSURE(menu.uuid, '00000000-0000-0000-0000-000000000000');
            this.title = this.ENSURE(menu.title, this.title);
            this.subtitle = this.ENSURE(menu.subtitle, this.subtitle);
            this.position = this.ENSURE(menu.position, 'topleft');
            this.color = menu.color || this.color;
            this.items = menu.items || [];
            this.show = true;
            this.menu = true;

            this.POST(`http://menuv/opened`, { uuid: this.uuid, r: this.resource });
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
            this.resource = 'menuv';
            this.menu = false;
            this.show = false;
            this.icon = 'none';
            this.uuid = '00000000-0000-0000-0000-000000000000';
            this.title = 'MenuV';
            this.subtitle = '';
            this.position = 'topleft';
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
        LABEL: function(input: string): string {
            if (input.length <= 20) { return input; }
            return `${input.substring(0, 20)}...`;
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
            if (!this.menu) { return; }

            const k = key as 'UP' | 'DOWN' | 'LEFT' | 'RIGHT' | 'ENTER' | 'CLOSE'

            if (typeof k == 'undefined' || k == null) {
                return
            }

            const keyRef = `KEY_${k}` as 'KEY_UP' | 'KEY_DOWN' | 'KEY_LEFT' | 'KEY_RIGHT' | 'KEY_ENTER' | 'KEY_CLOSE';

            if (this[keyRef]) {
                this[keyRef]();
            }
        },
        RESOURCE_STOPPED({ resource }: { resource: string }) {
            if (!this.menu) { return; }

            if (this.resource == resource) {
                this.RESET_MENU();
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
            if (this.items.length <= this.index) { return; }

            const item = this.items[this.index];

            if (item.type == 'button' || item.type == 'menu' || item.type == 'label' || item.type == 'unknown') { return; }

            switch(item.type) {
                case 'confirm':
                case 'checkbox':
                    const boolean_value = item.value as boolean;

                    this.items[this.index].value = !boolean_value;

                    break;
                case 'range':
                    let range_value = item.value as number;

                    if ((range_value - 1) <= item.min) { this.items[this.index].value = item.min; }
                    else if ((range_value - 1) >= item.max) { this.items[this.index].value = item.max; }
                    else { this.items[this.index].value--; }

                    break;
                case 'slider':
                    const slider_value = item.value as number;
                    const slider_values = item.values || [];

                    if (slider_values.length <= 0) { return; }
                    if ((slider_value - 1) < 0 || (slider_value - 1) >= slider_values.length) { this.items[this.index].value = (slider_values.length - 1); }
                    else { this.items[this.index].value--; }

                    break;
            }
        },
        KEY_RIGHT: function() {
            if (this.items.length <= this.index) { return; }

            const item = this.items[this.index];

            if (item.type == 'button' || item.type == 'menu' || item.type == 'label' || item.type == 'unknown') { return; }

            switch(item.type) {
                case 'confirm':
                case 'checkbox':
                    const boolean_value = item.value as boolean;

                    this.items[this.index].value = !boolean_value;

                    break;
                case 'range':
                    let range_value = item.value as number;

                    if ((range_value + 1) <= item.min) { this.items[this.index].value = item.min; }
                    else if ((range_value + 1) >= item.max) { this.items[this.index].value = item.max; }
                    else { this.items[this.index].value++; }

                    break;
                case 'slider':
                    const slider_value = item.value as number;
                    const slider_values = item.values || [];

                    if (slider_values.length <= 0) { return; }
                    if ((slider_value + 1) < 0 || (slider_value + 1) >= slider_values.length) { this.items[this.index].value = 0; }
                    else { this.items[this.index].value++; }

                    break;
            }
        },
        KEY_ENTER: function() {
            if (this.items.length <= this.index) { return; }0

            const item = this.items[this.index];

            switch(item.type) {
                case 'button':
                case 'menu':
                    this.POST(`http://menuv/submit`, { uuid: item.uuid, value: null, r: this.resource });
                    break;
                case 'confirm':
                    this.POST(`http://menuv/submit`, { uuid: item.uuid, value: item.value as boolean, r: this.resource });
                    break;
                case 'range':
                    let range_value = item.value as number;

                    if (range_value <= item.min) { range_value = item.min; }
                    else if (range_value >= item.max) { range_value = item.max; }
                    
                    this.POST(`http://menuv/submit`, { uuid: item.uuid, value: range_value, r: this.resource });
                    break;
                case 'checkbox':
                    const boolean_value = item.value as boolean;

                    this.items[this.index].value = !boolean_value;

                    this.POST(`http://menuv/submit`, { uuid: item.uuid, value: this.items[this.index].value, r: this.resource });
                    break;
                case 'slider':
                    let slider_value = item.value as number;
                    const slider_values = item.values || [];

                    if (slider_values.length <= 0 || slider_value < 0 || slider_value >= slider_values.length) { return; }
                   
                    this.POST(`http://menuv/submit`, { uuid: item.uuid, value: slider_value, r: this.resource });
                    break;
            }
        },
        KEY_CLOSE: function() {
            this.POST(`http://menuv/close`, { uuid: this.uuid, r: this.resource });
            this.CLOSE_MENU();
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