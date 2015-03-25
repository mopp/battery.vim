"=====================================================================================================
" Name:         autoload/battery.vim
" Author:       mfumi
" Email:        m.fumi760@gmail.com
" Modifier:     mopp
" Description:  Display battery infomation
" Last Change:  25-03-2015
" Version:      0.12
"=====================================================================================================

let s:save_cpo = &cpo
set cpo&vim


function! s:warn(msg)
    echohl WarningMsg
    echo a:msg
    echohl None
endfunction

function! s:debug(var,msg)
    if exists('g:battery_debug') && g:battery_debug > 0
        let {a:var} = a:msg
    endif
endfunction


" Return value : Dictionary
" |-----------------------------------------------------------------------------------------------------------|
" | KEY  (format)               |  VALUE                                                         | Mac | Unix |
" |----------------------------------------------------------------------------------------------|-----|------|
" | capacity (%c)               |  Current capacity (mAh or mWh)                                 |     |      |
" | rate (%r)                   |  Current rate of charge or discharge                           |     |      |
" | battery_status (%b)         |  Battery status (verbose)                                      |  *  |  *   |
" | battery_status_symbol (%s)  |  Battery status: high->'h', low->'l', critical->'!'            |  *  |  *   |
" |                             |  charging->'+', charged->'*'                                   |     |      |
" | temperature (%d)            |  Temperature (in degrees Celsius)                              |     |      |
" | power_source (%l)           |  AC line status (verbose)                                      |  *  |  *   |
" | load_percentage (%p)        |  Battery load percentage                                       |  *  |  *   |
" | minutes (%m)                |  Remaining time (to charge or discharge) in minutes            |  *  |  *   |
" | hours (%h)                  |  Remaining time (to charge or discharge) in hours              |  *  |  *   |
" | remaining_time (%t)         |  Remaining time (to charge or discharge) in the form `h:min'   |  *  |  *   |
" |-----------------------------------------------------------------------------------------------------------|


let s:info_format = {
            \ 'capacity':              '%c',
            \ 'rate':                  '%r',
            \ 'power_source':          '%l',
            \ 'battery_status':        '%b',
            \ 'battery_status_symbol': '%s',
            \ 'temperature':           '%d',
            \ 'load_percentage':       '%p',
            \ 'minutes':               '%m',
            \ 'hours':                 '%h',
            \ 'remaining_time':        '%t'
            \}
lockvar s:info_format


function! battery#getBatteryInfo()
    " Init
    let info = deepcopy(s:info_format)
    for i in keys(info)
        let info[i] = 'N/A'
    endfor

    if has('win32')
        " TODO
        return "Battery.vim not supports Windows :("
    elseif has('mac')
        let r = system('pmset -g ps')
        let p = matchlist(r, "Currentl\\?y drawing from '\\(AC\\|Battery\\) Power'")

        if !empty(p)
            let info['power_source'] = p[1]
        endif

        if match(r, "-InternalBattery-0[ \t]\\+") == -1
            return info
        endif

        let info['load_percentage'] = matchlist(r, "\\([0-9]\\{1,3\\}\\)%")[1]
        if match(r, "; charged") != -1
            let info['battery_status']        = 'charged'
            let info['battery_status_symbol'] = '*'
        elseif match(r, "; charging") != -1
            let info['battery_status']        = 'charging'
            let info['battery_status_symbol'] = '+'
        elseif info['load_percentage'] < g:battery_load_critical
            let info['battery_status']        = 'critical'
            let info['battery_status_symbol'] = '!'
        elseif info['load_percentage'] < g:battery_load_low
            let info['battery_status']        = 'low'
            let info['battery_status_symbol'] = 'l'
        else
            let info['battery_status']        = 'high'
            let info['battery_status_symbol'] = 'h'
        endif

        let time = matchlist(r, "\\(\\([0-9]\\+\\):\\([0-9]\\+\\)\\) remaining")
        if !empty(time)
            let info['remaining_time'] = time[1]
            let h                      = time[2]
            let m                      = time[3]
            let info['hours']          = h + ((m >= 30) ? 1 : 0)
            let info['minutes']        = m + h*60
        endif
    else
        if executable("acpi") != 1
            return "Please install acpi command."
        endif

        " Unix
        let info['power_source'] = (match(system('acpi -a'), 'off-line') == -1) ? ('AC') : ('Battery')

        let r = system('acpi -b')
        let info['load_percentage'] = matchlist(r, '\([0-9]\{1,3\}\)%')[1]

        if match(r, "Charged") != -1
            let info['battery_status']        = 'charged'
            let info['battery_status_symbol'] = '*'
        elseif match(r, "Charging,") != -1
            let info['battery_status']        = 'charging'
            let info['battery_status_symbol'] = '+'
        elseif info['load_percentage'] < g:battery_load_critical
            let info['battery_status']        = 'critical'
            let info['battery_status_symbol'] = '!'
        elseif info['load_percentage'] < g:battery_load_low
            let info['battery_status']        = 'low'
            let info['battery_status_symbol'] = 'l'
        else
            let info['battery_status']        = 'high'
            let info['battery_status_symbol'] = 'h'
        endif

        let time = matchlist(r, '\(\([0-9]\+\):\([0-9]\+\):\([0-9]\+\)\) \(remaining\|until\)')
        if !empty(time)
            let info['remaining_time'] = time[1]
            let h                      = time[2]
            let m                      = time[3]
            let info['hours']          = h + ((m >= 30) ? 1 : 0)
            let info['minutes']        = m + h * 60
        endif
    endif

    return info
endfunction



function! battery#battery(format)
    let format = a:format

    let info = battery#getBatteryInfo()
    call s:debug('g:battery_debug_info',info)

    " If this plugin runs on not supports OS, battery#getBatteryInfo() returns error message.
    if type(info) == type('')
        return info
    endif

    " Set each parameters by format.
    for i in keys(info)
        if format =~# s:info_format[i]
            let format = substitute(format, s:info_format[i], info[i], "g")
        endif
    endfor

    return format
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
