" Vim indent file
" Language:	Lua script
" Modified By: Raymond W. Ko <raymond.w.ko '__@__at@yahoo.com__@__' gmail.com>
" Maintainer:	Marcus Aurelius Farias <marcus.cf 'at' bol.com.br>
" First Author:	Max Ischenko <mfi 'at' ukr.net>
" Last Change:	2013 Apr 11

setlocal indentexpr=GetLuaIndent2()
setlocal autoindent

" To make Vim call GetLuaIndent() when it finds '\s*end' or '\s*until'
" on the current line ('else' is default and includes 'elseif').
setlocal indentkeys+=0=end,0=until,0=elseif,0=else,0=:

" Only define the function once.
if exists("*GetLuaIndent2")
  finish
endif

function s:IsLineBlank(link)
  if match(line, '\v^\s*$') > -1
    return 1
  else
    return 0
  endif
endfunction

function s:PrevNonBlank(line_num)
  while 1
    if a:line_num <= 0
      return 0
    endif

    let line = getline(a:line_num)
    if !s:IsLineBlank(line)
      return a:line_num
    endif

    let a:line_num -= 1
  endwhile
endfunction

function s:IsBlockBegin(line)
    return match(a:line, '^\s*\%(if\>\|for\>\|while\>\|repeat\>\|else\>\|elseif\>\|do\>\|then\>\)')
endfunction

function s:GetStringIndent(str)
  let indent = match(a:str, '\S')
  if indent < 0 then
    let indent = 0
  endif
  return indent
endfunction

" Get the indent of the previous "line", which can span multiple real lines
" due to a series of arguments and etc.
function! s:GetPrevIndent()
  let i = v:lnum - 1
  while 1
    let line = getline(i)

    if s:IsBlockBegin(line)
      return s:GetStringIndent(line)
    endif
    
    " part of a function call, or table
    if match(line, '\v^.+,\s*') > -1
    endif
  endwhile
  return 4
endfunction

function! GetLuaIndent2()
  " base case or first line
  if v:lnum - 1 <= 0
    return 0
  endif

  let indent = s:GetPrevIndent()
  return indent
endfunction

finish

function! GetLuaIndent_BeginningFunctionIndex(line)
    return match(a:line, '\<function\>\s*\%(\k\|[.:]\)\{-}\s*(')
endfunction

function! GetLuaIndent()
    " Find a non-blank line above the current line.
    let prevlnum = prevnonblank(v:lnum - 1)

    " Hit the start of the file, use zero indent.
    if prevlnum == 0
        return 0
    endif

    " Add a 'shiftwidth' after lines that start a block:
    " 'function', 'if', 'for', 'while', 'repeat', 'else', 'elseif', '{'
    let ind = indent(prevlnum)
    let prev_line = getline(prevlnum)
    let match_index = GetLuaIndent_IndentingKeywordsIndex(prev_line)
    if match_index == -1
        let match_index = match(prev_line, '{\s*$')
        if match_index == -1
            let match_index = GetLuaIndent_BeginningFunctionIndex(prev_line)
        endif
    endif

    if prev_line =~# '^\s*end.\+$'
        return ind
    endif

    if match_index != -1
        " Add 'shiftwidth' if what we found previously is not in a comment and
        " an "end" or "until" is not present on the same line.
        if synIDattr(synID(prevlnum, match_index + 1, 1), "name") != "luaComment" && prev_line !~ '\<end\>\|\<until\>'
            let ind = ind + &shiftwidth
        endif
    endif

    " Subtract a 'shiftwidth' on end, else (and elseif), until and '}'
    " This is the part that requires 'indentkeys'.
    let match_index = match(getline(v:lnum), '^\s*\%(end\|else\|until\|}\)')
    if match_index != -1 && synIDattr(synID(v:lnum, match_index + 1, 1), "name") != "luaComment"
        let ind = ind - &shiftwidth
    endif

    " if the previous line is a comment, then we don't need to check if
    " parentheses are unbalanced, just used to computed indent
    if match(prev_line, '^\s*--.*$') != -1
        return ind
    endif

    let has_function_kw = match(getline(v:lnum - 1), '.*\s*function\s*.*')
    let has_end_kw = match(getline(v:lnum - 1), '.*\s*function.*end\s*.*')
    let has_func_opening = 0
    if has_function_kw != -1 && has_end_kw == -1
        let has_func_opening = 1
    endif

    " below code tries to find unbalanced parentheses and determine special
    " indenting amounts so argument line up nicely
    let num_parens = 0
    let text_after_paren = 0
    let after_left_index = 0
    let i = strlen(prev_line) - 1
    while i >= 0
        if prev_line[i] == '('
            let num_parens -= 1
        elseif prev_line[i] == ')'
            let num_parens += 1
        else
            if (num_parens == 0)
                let after_left_index = i
            endif
        endif
        if (num_parens == 0)
            let text_after_paren = 1
        elseif num_parens > 0
            let text_after_paren = 0
        endif
        let i -= 1
    endwhile

    " open left paren
    if num_parens < 0
        if !has_func_opening
            if text_after_paren
                let ind = after_left_index
            elseif (GetLuaIndent_IndentingKeywordsIndex(prev_line) == -1) && (GetLuaIndent_BeginningFunctionIndex(prev_line) == -1)
                let ind += &shiftwidth
            endif
        endif
        " open right paren
    elseif num_parens > 0
        " search for line with an open left paren, use it's indent + shiftwidth
        let line_index = prevlnum - 1
        let open_left_parent_indent = 0
        let line = ""

        while line_index > 0
            let line = getline(line_index)
            let i = strlen(line) - 1
            let open_left_paren = 0

            while i >= 0
                if line[i] == ')'
                    break
                elseif line[i] == '('
                    let open_left_paren = 1
                    break
                endif

                let i -= 1
            endwhile

            if open_left_paren
                let open_left_parent_indent = indent(line_index)
                break
            endif

            let line_index -= 1
        endwhile

        let ind = open_left_parent_indent
        if (GetLuaIndent_IndentingKeywordsIndex(line) != -1) || (GetLuaIndent_BeginningFunctionIndex(line) != -1)
            let ind += &shiftwidth
        endif

        " Subtract a 'shiftwidth' on end, else (and elseif), until and '}'
        " This is the part that requires 'indentkeys'.
        let match_index = match(getline(v:lnum), '^\s*\%(end\|else\|until\|}\)')
        if match_index != -1 && synIDattr(synID(v:lnum, match_index + 1, 1), "name") != "luaComment"
            let ind = ind - &shiftwidth
        endif
    endif

    if (match(getline(v:lnum), '^\s*:.*') != -1)
        let prev_line = getline(v:lnum - 1)
        let colon_loc = match(prev_line, ':')
        if (colon_loc != -1)
            let ind = colon_loc
        else
            let ind += &shiftwidth
        endif
    endif

    return ind
endfunction
