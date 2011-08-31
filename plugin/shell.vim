" Vim plug-in
" Author: Peter Odding <peter@peterodding.com>
" Last Change: August 31, 2011
" URL: http://peterodding.com/code/vim/shell/

" Support for automatic update using the GLVS plug-in.
" GetLatestVimScripts: 3123 1 :AutoInstall: shell.zip

" Don't source the plug-in when it's already been loaded or &compatible is set.
if &cp || exists('g:loaded_shell')
  finish
endif

" Configuration defaults. {{{1

if !exists('g:shell_mappings_enabled')
  " Set this to false (0) if you don't like the default mappings.
  let g:shell_mappings_enabled = 1
endif

" Automatic commands. {{{1

augroup PluginShell
  " These enable automatic highlighting of URLs and e-mail addresses.
  autocmd! BufNew,BufRead,Syntax * call xolox#shell#highlight_urls()
augroup END

" Regular commands. {{{1

command! -bar -nargs=? -complete=file Open call xolox#shell#open_cmd(<q-args>)
command! -bar Fullscreen call xolox#shell#fullscreen()

" Default key mappings. {{{1

if g:shell_mappings_enabled
  inoremap <F11> <C-o>:Fullscreen<CR>
  nnoremap <F11> :Fullscreen<CR>
  inoremap <F6> <C-o>:Open<CR>
  nnoremap <F6> :Open<CR>
endif

" Make sure the plug-in is only loaded once.
let g:loaded_shell = 1

" vim: ts=2 sw=2 et fdm=marker
