"=====================================================================================================
" Name:         plugin/battery.vim
" Author:       mfumi
" Email:        m.fumi760@gmail.com
" Modifier:     mopp
" Description:  Display battery infomation
" Last Change:  25-03-2015
" Version:      0.11
"=====================================================================================================

if exists('g:loaded_battery_vim')
    finish
endif
let g:loaded_battery_vim = 1

let s:save_cpo = &cpo
set cpo&vim


let g:battery_status_format = get(g:, 'battery_status_format', '%l power, battery %b (%p% load, remaining time %t)')
let g:battery_load_critical = get(g:, 'battery_load_critical', 10)
let g:battery_load_low      = get(g:, 'battery_load_low', 25)

command! -nargs=0 Battery echo battery#battery(g:battery_status_format)


let &cpo = s:save_cpo
unlet s:save_cpo
