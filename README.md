vim-lua-indent
==============

A somewhat better Lua indent script for Vim

This is a hastily hacked on version of the lua.vim indent file that ships with
Vim. It auto-indents much better than the default one, especially when you have
function arguments that span multiple lines inside of conditionals or just a
function's multi-line argument list itself.

For an example of what it can accomplish, go here:
https://gist.github.com/4208232

INSTALL
-------
Copy the lua.vim file into the indent/ folder of your $HOME/.vim/ or $HOME/vimfiles/ directory.
Or, use vim-pathogen to manage it as a bundle (recommended).
