<!--
----------------------- [ MenuV ] -----------------------
-- GitHub: https://github.com/ThymonA/menuv/
-- License: GNU General Public License v3.0
--          https://choosealicense.com/licenses/gpl-3.0/
-- Author: Thymon Arens <contact@arens.io>
-- Name: MenuV
-- Version: 1.0.0
-- Description: FiveM menu libarary for creating menu's
----------------------- [ MenuV ] -----------------------
-->
<template>
  <div id="menuv" class="menuv size-110" :class="{'hide': !show || !menu}" :data-uuid="uuid">
    <v-style>
      .menuv .menuv-header .menuv-bg-icon i,
      .menuv .menuv-header .menuv-bg-icon svg {
        color: rgb({{color.r}},{{color.g}},{{color.b}});
      }

      .menuv .menuv-subheader {
        background-color: rgb({{color.r}},{{color.g}},{{color.b}});
      }

      .menuv .menuv-items .menuv-item.active {
        border-left: 0.5em solid rgb({{color.r}},{{color.g}},{{color.b}});
        border-right: 0.5em solid rgb({{color.r}},{{color.g}},{{color.b}});
      }

      .menuv .menuv-items span.menuv-options span.menuv-btn.active {
        background-color: rgb({{color.r}},{{color.g}},{{color.b}});
      }

      .menuv .menuv-items .menuv-item.active span.menuv-options span.menuv-btn.active {
        background-color: rgb({{color.r}},{{color.g}},{{color.b}});
      }

      .menuv .menuv-items input[type="range"]::-webkit-slider-runnable-track {
        background: rgb({{color.r}},{{color.g}},{{color.b}});
      }

      .menuv .menuv-items .menuv-item.active input[type="range"]::-webkit-slider-thumb {
        background: rgb({{color.r}},{{color.g}},{{color.b}});
        border: 1px solid rgba({{color.r}},{{color.g}},{{color.b}}, 0.25);
      }

      .menuv .menuv-items input[type="range"]:focus::-webkit-slider-runnable-track {
        background: rgb({{color.r}},{{color.g}},{{color.b}});
      }

      .menuv .menuv-items .menuv-desc {
        border-left: 0.375em solid rgb({{color.r}},{{color.g}},{{color.b}});
      }
    </v-style>
    <header class="menuv-header">
      <strong>{{title}}</strong>
        <span class="menuv-bg-icon">
          <i v-if="icon != 'none'" :class="icon"></i>
        </span>
    </header>
    <nav class="menuv-subheader">
      {{subtitle}}
    </nav>
    <ul class="menuv-items">
      <li class="menuv-item" v-for="item in items" :key="item.uuid" :class="{'active': (index + 1) == item.index}">
        <span class="menuv-icon" v-if="ENSURE(item.icon, 'none') != 'none'">{{ENSURE(item.icon, 'none')}}</span>
        {{LABEL(item.label)}}
        <i class="fas fa-arrow-right" v-if="item.type == 'menu'"></i>
        <i v-if="item.type == 'checkbox'" :class="{'fas fa-check': item.value, 'far fa-square': !item.value}"></i>
        <input type="range" :min="item.min" :max="item.max" :value="(item.value)" v-if="item.type == 'range'">
        <span class="menuv-options" v-if="item.type == 'confirm'">
          <span class="menuv-btn" :class="{'active': item.value}">YES</span>
          <span class="menuv-btn" :class="{'active': !item.value}">NO</span>
        </span>
        <span class="menuv-label" v-if="item.type == 'label'">
          {{item.value}}
        </span>
        <span class="menuv-options" v-if="item.type == 'slider'">
          <i class="fas fa-chevron-left"></i>
            {{GET_SLIDER_LABEL({ uuid: item.uuid })}}
          <i class="fas fa-chevron-right"></i>
        </span>
      </li>
    </ul>
    <footer class="menuv-description" :class="{'hide': IS_DEFAULT(GET_CURRENT_DESCRIPTION())}">
      <strong v-html="GET_CURRENT_DESCRIPTION()"></strong>
    </footer>
  </div>
</template>

<script lang="ts" src="./../menuv.ts"></script>