" Vim indent file
" Language:	Lua script
" Modified By: Raymond W. Ko <raymond.w.ko '__@__at@yahoo.com__@__' gmail.com>
" Maintainer:	Marcus Aurelius Farias <marcus.cf 'at' bol.com.br>
" First Author:	Max Ischenko <mfi 'at' ukr.net>
" Last Change:	2014 Nov 12

setlocal indentexpr=GetLuaIndent2()
setlocal autoindent

" To make Vim call GetLuaIndent() when it finds '\s*end' or '\s*until'
" on the current line ('else' is default and includes 'elseif').
setlocal indentkeys+=0=end,0=until,0=elseif,0=else,0=:

" Only define the function once.
if exists("*GetLuaIndent2")
  finish
endif

function s:IsLineBlank(line)
  if match(a:line, '\v^\s*$') > -1
    return 1
  else
    return 0
  endif
endfunction

function s:IsBlockBegin(line)
  if match(a:line, '\v^\s*%(if>|for>|while>|repeat>|else>|elseif>|do>|then>|function>)\s*') > -1
    return 1
  else
    return 0
  endif
endfunction

function s:IsBlockEnd(line)
  if match(a:line, '^\v\s*%(end>|else>|elseif>|until>|\})') > -1
    return 1
  else
    return 0
  endif
endfunction

function s:GetStringIndent(str)
  let indent = match(a:str, '\S')
  if indent < 0
    let indent = 0
  endif
  return indent
endfunction

function s:IsParenBalanced(line)
  let balance = 0
  for i in range(len(a:line))
    if a:line[i] == '('
      let balance += 1
    elseif a:line[i] == ')'
      let balance -= 1
    endif
  endfor
  
  if balance == 0
    return 1
  else
    return 0
  endif
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

  if balance == 0
    return 1
  else
    return 0
  endif
endfunction

function s:IsTableBegin(line)
  if match(a:line, '.*{.*}.*') > -1
    return 0
  endif

  if match(a:line, '.*{.*') > -1
    return 1
  else
    return 0
  endif
endfunction

function s:HasFuncCall(line)
  if match(a:line, '\v\S+\(.*') > -1
    return 1
  endif

  return 0
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

  let i = v:lnum - 1
  while 1
    if i <= 0
      return 0
    endif
    let line = getline(i)
    if s:IsLineBlank(line)
      let i -= 1
      continue
    endif

    call insert(lines, line, 0)

    if s:IsBlockBegin(line)
      break
    endif
    
    " part of a function call argument list, or table
    if match(line, '\v^.+,\s*') > -1
      let i -= 1
      continue
    endif

    if s:IsParenBalanced(line) || s:IsTableBegin(line) || s:HasFuncCall(line)
      break
    endif

    let i -= 1
  endwhile

  return lines
endfunction

function! s:FindFirstUnbalancedParen(lines)
  let balance = 0
  let line_indent = 0
  for line_index in range(v:lnum - 1, 0, -1)
    let line = getline(line_index)
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
      return s:GetStringIndent(line)
    endif
  endfor

  return 0
endfunction

function! GetLuaIndent2()
  " base case or first line
  if v:lnum - 1 <= 0
    return 0
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
    if s:IsBlockBegin(prev_lines[0]) || s:IsTableBegin(prev_lines[0])
      let indent += &shiftwidth
    endif
  else
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
