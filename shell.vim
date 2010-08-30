" Vim plug-in
" Author: Peter Odding <peter@peterodding.com>
" Last Change: August 30, 2010
" URL: http://peterodding.com/code/vim/shell/
" License: MIT
" Version: 0.7.3

" Support for automatic update using the GLVS plug-in.
" GetLatestVimScripts: 3123 1 :AutoInstall: shell.zip

" Configuration defaults. {{{1

if !exists('g:shell_mappings_enabled')
  " Set this to false (0) if you don't like the default mappings.
  let g:shell_mappings_enabled = 1
endif

if !exists('g:shell_fullscreen_items')
  " Change this if :Fullscreen shouldn't hide the menu/toolbar/tabline.
  let g:shell_fullscreen_items = 'mTe'
endif

if !exists('g:shell_open_cmds')
  " This is only needed on UNIX, should already support most platforms.
  let g:shell_open_cmds = ['gnome-open', 'kde-open', 'exo-open', 'xdg-open']
endif

if !exists('g:shell_hl_exclude')
  " URL highlighting breaks highlighting of <a href="..."> tags in HTML.
  let g:shell_hl_exclude = '^\(x|ht\)ml$'
endif

if !exists('g:shell_patt_url')
 let g:shell_patt_url = '\<\w\{3,}://\(\S*\w\)\+[/?#]\?'
endif

if !exists('g:shell_patt_mail')
 let g:shell_patt_mail = '\<\w[^@ \t\r]*\w@\w[^@ \t\r]\+\w\>'
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

" vim: ts=2 sw=2 et fdm=marker
