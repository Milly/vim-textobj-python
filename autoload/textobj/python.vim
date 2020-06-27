" Text objects for Python
" Version 0.4.1
" Copyright (C) 2013 Brian Smyth <http://bsmyth.net>
" License: So-called MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}

function! s:skip_pair(start, end, ...) abort
    let l:flag = (a:000 + [''])[0]
    let l:cur_pos = getpos('.')
    if l:flag =~# 'b'
        call search(a:end, 'bcW', l:cur_pos[1])
    else
        call search(a:start, 'cW', l:cur_pos[1])
    endif
    if searchpair(a:start, '', a:end, l:flag.'rW') <= 0
        call cursor(l:cur_pos[1:])
        return 0
    endif
    return 1
endfunction

function! s:next_non_blank_or_comment(linenr) abort
    let l:linenr = a:linenr
    while 1
        let l:linenr = nextnonblank(l:linenr)
        if l:linenr is# 0 || getline(l:linenr) !~# '^\s*#'
            return l:linenr
        endif
        let l:linenr += 1
    endwhile
endfunction

function! s:prev_non_blank_or_comment(linenr) abort
    let l:linenr = a:linenr
    while 1
        let l:linenr = prevnonblank(l:linenr)
        if l:linenr is# 0 || getline(l:linenr) !~# '^\s*#'
            return l:linenr
        endif
        let l:linenr -= 1
    endwhile
endfunction

" Find the start position of the block at given defn pattern
" Return 0, if there is none.
function! textobj#python#find_defn_pos(pattern)
    let l:save_pos = getpos('.')

    " Skip parens backward
    call s:skip_pair('\[', '\]', 'b')
    call s:skip_pair('(', ')', 'b')

    " Skip decorators
    while getline('.') =~# '^\s*@'
        call s:skip_pair('(', ')')
        let l:linenr = s:next_non_blank_or_comment(line('.') + 1)
        if l:linenr is# 0
            " EOF
            call cursor(l:save_pos[1:])
            return 0
        endif
        call cursor(l:linenr, 1)
    endwhile

    " If current line is defn, then return
    call cursor(0, 1)
    if search('^\s*\zs'.a:pattern.' ', 'c', line('.'))
        return getpos('.')
    endif

    " Find a defn backward
    let l:cur_pos = getpos('.')
    let l:cur_indent = indent('.')
    while 1
        if !search('^\s*\zs'.a:pattern.' ', 'bW')
            " We didn't find a suitable defn
            call cursor(l:save_pos[1:])
            return 0
        endif
        let l:defn_pos = getpos('.')
        let l:defn_indent = indent(l:defn_pos[1])
        if l:defn_indent < l:cur_indent
            break
        endif
        " This is a defn at the same level or deeper, keep searching
    endwhile

    " Skip multiline arguments and typings
    call s:skip_pair('(', ')')
    call s:skip_pair('\[', '\]')

    " Found a defn, make sure there aren't any statements at a
    " shallower indent level in between
    for l:l in range(line('.') + 1, l:cur_pos[1])
        if getline(l:l) !~# '^\s*\%(#.*\)\?$' && indent(l:l) <= l:defn_indent
            call cursor(l:save_pos[1:])
            return 0
        endif
    endfor

    call cursor(l:defn_pos[1:])
    return l:defn_pos
endfunction

" Find the position with the first (valid) decorator above defn position.
" Return the defn position, if there is none.
function! textobj#python#find_prev_decorators_pos(defn_pos)
    let l:last_pos = a:defn_pos[:]
    let l:linenr = a:defn_pos[1]
    let l:defn_indent = indent(l:linenr)
    while 1
        " Get the first not blank line
        let l:linenr = s:prev_non_blank_or_comment(l:linenr - 1)
        if l:linenr is# 0
            " There is not above current one.
            break
        endif

        " Skip parens backward
        call cursor(l:linenr, 0)
        call s:skip_pair('(', ')', 'b')
        let l:linenr = line('.')

        " The decorator should be in the same level as defn
        if search('^\s*\zs@', 'bcW', l:linenr) && indent(line('.')) == l:defn_indent
            let l:last_pos = getpos('.')
            continue
        endif

        " There is not a (valid) decorator
        break
    endwhile
    call cursor(l:last_pos[1:])
    return l:last_pos
endfunction

" Find the start position of the block inner at given defn position.
function! textobj#python#find_defn_inner_pos(defn_pos)
    " Put the cursor on the def line
    call cursor(a:defn_pos[1:])

    " Skip multiline arguments and typings
    call s:skip_pair('(', ')')
    call s:skip_pair('\[', '\]')

    if search(':\s*\zs#\@!\S.*$', 'cz', line('.'))
        " It is a one-liner
    else
        " Start from the beginning of the next line
        call cursor(line('.') + 1, 1)
    endif

    return getpos('.')
endfunction

" Find the last position of the block at given defn position.
function! textobj#python#find_last_pos(defn_pos)
    " Put the cursor on the def inner position
    let l:end_pos = textobj#python#find_defn_inner_pos(a:defn_pos)

    if l:end_pos[2] > 1
        " It is a one-liner
    else
        " Find the last line of deeper indent lines
        let l:defn_indent = indent(a:defn_pos[1])
        let l:linenr = l:end_pos[1]
        while 1
            let l:linenr = nextnonblank(l:linenr + 1)
            if l:linenr is# 0
                " EOF
                break
            endif
            if indent(l:linenr) <= l:defn_indent
                " de-indented
                if getline(l:linenr) =~# '^\s*#'
                    " Skip de-indented commend
                    continue
                endif
                break
            endif
            let l:end_pos[1] = l:linenr
        endwhile
    endif

    " Put the cursor on the end of line
    let l:end_pos[2] = col([l:end_pos[1], '$'])
    call cursor(l:end_pos[1:])
    return l:end_pos
endfunction

function! s:find_defn_selection(pattern)
    call cursor(s:next_non_blank_or_comment(line('.')), 0)
    let l:defn_pos = textobj#python#find_defn_pos(a:pattern)
    if empty(l:defn_pos)
        return 0
    endif
    let l:end_pos = textobj#python#find_last_pos(l:defn_pos)
    return ['V', l:defn_pos, l:end_pos]
endfunction

function! s:select_surrounding_blank_lines(pos)
    let l:defn_pos = copy(a:pos)

    let l:blanks_on_start = l:defn_pos[1][1] - (prevnonblank(l:defn_pos[1][1] - 1) + 1)
    let l:current_block_indent_level = indent(l:defn_pos[1][1])
    let l:next_block_linenr = nextnonblank(l:defn_pos[2][1] + 1)
    let l:next_block_indent_level = indent(l:next_block_linenr)

    if l:next_block_linenr != 0
        if l:current_block_indent_level != 0 && l:next_block_indent_level == 0
        let l:desired_blanks = 2
        let l:desired_blanks = max([0, l:desired_blanks - l:blanks_on_start])
            let l:defn_pos[2][1] = l:next_block_linenr - 1 - l:desired_blanks
    else
            let l:defn_pos[2][1] = l:next_block_linenr - 1
    endif
    else
        let l:defn_pos[1][1] = prevnonblank(l:defn_pos[1][1] - 1) + 1
    endif
    return l:defn_pos
endfunction

function! textobj#python#select_a(pattern)
    let l:cur_pos = getpos('.')
    let l:defn_sel = s:find_defn_selection(a:pattern)
    if !empty(l:defn_sel)
        let l:defn_sel[1] = textobj#python#find_prev_decorators_pos(l:defn_sel[1])
        let l:defn_sel = s:select_surrounding_blank_lines(l:defn_sel)
        return l:defn_sel
    endif
    return 0
endfunction

function! textobj#python#select_i(pattern)
    let l:defn_sel = s:find_defn_selection(a:pattern)
    if !empty(l:defn_sel)
        let l:defn_sel[1] = textobj#python#find_defn_inner_pos(l:defn_sel[1])
        if l:defn_sel[1][1] is# l:defn_sel[2][1]
            " It is a one-liner
            let l:defn_sel[0] = 'v'
        endif
        return l:defn_sel
    endif
    return 0
endfunction

function! textobj#python#class_select_a()
    return textobj#python#select_a('class')
endfunction

function! textobj#python#class_select_i()
    return textobj#python#select_i('class')
endfunction

function! textobj#python#function_select_a()
    return textobj#python#select_a('\(async def\|def\)')
endfunction

function! textobj#python#function_select_i()
    return textobj#python#select_i('\(async def\|def\)')
endfunction

function! textobj#python#function_select(object_type)
  return textobj#python#function_select_{a:object_type}()
endfunction
