" Vim indent file
" Language:	Lua script
" Maintainer: Raymond W. Ko <raymond.w.ko 'at' gmail.com>
" Former Maintainer:	Marcus Aurelius Farias <marcus.cf 'at' bol.com.br>
" First Author:	Max Ischenko <mfi 'at' ukr.net>
" Last Change:	2014 Nov 13

setlocal indentexpr=GetLuaIndent()
setlocal autoindent

" To make Vim call GetLuaIndent() when it finds '\s*end' or '\s*until'
" on the current line ('else' is default and includes 'elseif').
setlocal indentkeys+=0=end,0=until,0=elseif,0=else,0=:

" Only define the function once.
if (exists("GetLuaIndentVersion") && g:GetLuaIndentVersion == 2)
  finish
endif
let g:GetLuaIndentVersion = 2

function s:IsLineBlank(line)
  return a:line =~# '\m\v^\s*$'
endfunction

function s:IsBlockBegin(line)
  if a:line =~# '\m\v^\s*%(if>|for>|while>|repeat>|else>|elseif>|do>|then>|function>|local\s*function>)'
    return 1
  endif

  if a:line =~# '\m\v^.*\s*\=\s*function>.*'
    return 1
  endif

  return 0
endfunction

function s:IsBlockEnd(line)
  return a:line =~# '\m\v^\s*%(end>|else>|elseif>|until>|\})'
endfunction

function s:IsTableBegin(line)
  if (a:line =~# '\m.*{.*}.*')
    return 0
  elseif (a:line =~# '\m.*{.*')
    return 1
  else
    return 0
  endif
endfunction

function s:HasFuncCall(line)
  return a:line =~# '\m\v\S+\(.*'
endfunction

function s:IsSingleLineComment(line)
  return a:line =~# '\m\v.*--.*'
endfunction

function s:synname(...) abort
  return synIDattr(synID(a:1, a:2, 1), 'name')
endfunction

function s:IsMultiLineString()
  return s:synname(v:lnum, 1) == 'luaString2'
endfunction

function s:IsMultiLineComment()
  if getline('.') =~# '\m\v.*--.*'
    return 0
  endif
  return s:synname(v:lnum, 1) == 'luaComment'
endfunction

" TODO: do we have to expand tabs to shiftwidth here?
function s:GetStringIndent(str)
  let indent = match(a:str, '\S')
  if indent < 0
    let indent = 0
  endif
  return indent
endfunction

function s:LinesParenBalanced(lines)
  let balance = 0
  for line in a:lines
    for i in range(len(line))
      if line[i] == '('
        let balance += 1
      elseif line[i] == ')'
        let balance -= 1
      endif
    endfor
  endfor

  return balance == 0
endfunction

function s:IsParenBalanced(line)
  return s:LinesParenBalanced([a:line])
endfunction

" Retrieve the previous relevants lines used to determine indenting.
"
" Hopefully most of the times it will be a single line like:
" ....foo = bar + 1
" ....foo()
"
" But sometimes it can get complicated like:
" func(arg1,
" .....arg2,
" .....arg3,
"
" or even
" if (long_func_call(arg1,
" ...................arg2,
" ...................arg3))
" ....return foo
" end
function! s:GetPrevLines()
  let lines = []

  let i = v:lnum
  let multiline = 0
  while 1
    let i -= 1
    if i <= 0
      return 0
    endif

    let line = getline(i)

    if multiline
      if !(line =~# '\m\v.*\[\[.*')
        continue
      else
        let multiline = 0
      endif
    endif
    if (line =~# '\m\v.*\]\].*')
      let multiline = 1
      continue
    endif

    if s:IsLineBlank(line)
      continue
    endif

    call insert(lines, line, 0)

    if s:IsBlockBegin(line) || s:IsSingleLineComment(line)
      break
    endif
    
    " part of a function call argument list, or table
    if match(line, '\v^.+,\s*') > -1
      continue
    endif

    if s:IsParenBalanced(line) || s:IsTableBegin(line) || s:HasFuncCall(line)
      break
    endif
  endwhile

  return lines
endfunction

" Tries the best effort to the find the opening '(' which marks a multi line
" expression. However, sometimes it well balanced, meaning there is not such
" opening locally, or such an opening would give too much indent (immediate
" anonymous function as argument)
function! s:FindFirstUnbalancedParen(lines)
  let balance = 0
  let line_indent = 0
  let multiline = 0

  for line_index in range(v:lnum - 1, 0, -1)
    let line = getline(line_index)

    if multiline
      if !(line =~# '\m\v.*\[\[.*')
        continue
      else
        let multiline = 0
      endif
    endif
    if (line =~# '\m\v.*\]\].*')
      let multiline = 1
      continue
    endif

    " remove comments from consideration
    let line = substitute(line, '\v\m--.*$', '')
    let line = substitute(line, '\v\m\[\[.*$', '')

    " remove string escape to avoid confusing following regexps
    let line = substitute(line, '\v\m\\"', '', 'g')
    let line = substitute(line, '\v\m\\''', '', 'g')
    " remove strings from consideration
    let line = substitute(line, '\v\m".\{-}"', '', 'g')
    let line = substitute(line, '\v\m''.\{-}''', '', 'g')

    for i in range(strlen(line) - 1, 0, -1)
      if line[i] == ')'
        let balance += 1
      elseif line[i] == '('
        let balance -= 1
        if balance < 0
          if match(line, '\v^.+\(.*<function>' ) > -1
            return s:GetStringIndent(line) + &shiftwidth
          else
            return i + 1
          endif
        endif
      endif
    endfor

    " turns out it was not so unbalanced
    if balance == 0
      if s:IsLineBlank(line)
        continue
      endif
      return s:GetStringIndent(line)
    endif
  endfor

  return 0
endfunction

function! GetLuaIndent()
  " base case or first line
  if v:lnum - 1 <= 0
    return 0
  endif

  if s:IsMultiLineString() || s:IsMultiLineComment()
    return indent(v:lnum)
  endif

  let cur_line = getline(v:lnum)

  let prev_lines = s:GetPrevLines()
  let prev_lines_len = len(prev_lines)
  if prev_lines_len == 0
    return 0
  elseif prev_lines_len == 1
    let indent = s:GetStringIndent(prev_lines[0])
  else
    let indent = s:GetStringIndent(prev_lines[0])
  endif

  " if the previous "line" has a block begin, start a new indent
  if s:LinesParenBalanced(prev_lines)
    if s:IsSingleLineComment(prev_lines[0])
      " pass
    elseif s:IsBlockBegin(prev_lines[0]) || s:IsTableBegin(prev_lines[0])
      let indent += &shiftwidth
    endif
  else
    if s:IsSingleLineComment(prev_lines[-1])
      return s:GetStringIndent(prev_lines[-1])
    endif
    if !s:IsParenBalanced(prev_lines[-1])
      " function(
      " ....shiftwidth,
      if match(prev_lines[-1], '\v^.*\(\s*$') > -1
        let indent = s:GetStringIndent(prev_lines[-1]) + &shiftwidth
      else
        " function(arg1,
        " .........X
        let indent = s:FindFirstUnbalancedParen(prev_lines)
      endif
    else
      let indent = s:GetStringIndent(prev_lines[-1])
    endif
  endif

  if s:IsBlockEnd(cur_line)
    let indent -= &shiftwidth
  endif

  return indent
endfunction
