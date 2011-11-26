" Vim auto-load script
" Author: Peter Odding <peter@peterodding.com>
" Last Change: November 26, 2011
" URL: http://peterodding.com/code/vim/shell/

let g:xolox#shell#version = '0.9.23'

if !exists('s:fullscreen_enabled')
  let s:enoimpl = "%s() hasn't been implemented on your platform! %s"
  let s:contact = "If you have suggestions, please contact peter@peterodding.com."
  let s:fullscreen_enabled = 0
  let s:maximized = 0
endif

function! xolox#shell#open_cmd(arg) " -- implementation of the :Open command {{{1
  try
    " No argument?
    if a:arg !~ '\S'
      " Filename, URL or e-mail address at text cursor location?
      if !s:open_at_cursor()
        " Open the directory of the current buffer.
        let bufdir = expand('%:p:h')
        call xolox#misc#msg#debug("shell.vim %s: Opening directory of current buffer '%s'.", g:xolox#shell#version, bufdir)
        call xolox#misc#open#file(bufdir)
      endif
    elseif (a:arg =~ xolox#shell#url_pattern()) || (a:arg =~ xolox#shell#mail_pattern())
      " Open the URL or e-mail address given as an argument.
      call xolox#misc#msg#debug("shell.vim %s: Opening URL or e-mail address '%s'.", g:xolox#shell#version, a:arg)
      call xolox#misc#open#url(a:arg)
    else
      let arg = fnamemodify(a:arg, ':p')
      " Does the argument point to an existing file or directory?
      if isdirectory(arg) || filereadable(arg)
        call xolox#misc#msg#debug("shell.vim %s: Opening valid filename '%s'.", g:xolox#shell#version, arg)
        call xolox#misc#open#file(arg)
      else
        let msg = "I don't know how to open '%s'! %s"
        echoerr printf(msg, a:arg, s:contact)
      endif
    endif
  catch
    call xolox#misc#msg#warn("shell.vim %s: %s at %s", g:xolox#shell#version, v:exception, v:throwpoint)
  endtry
endfunction

function! s:open_at_cursor()
  let cWORD = expand('<cWORD>')
  " Start by trying to match a URL in <cWORD> because URLs can be more-or-less
  " unambiguously distinguished from e-mail addresses and filenames.
  if g:shell_verify_urls && cWORD =~ '^\(http\|https\)://.\{-}[[:punct:]]$' && xolox#shell#url_exists(cWORD)
    let match = cWORD
  else
    let match = matchstr(cWORD, xolox#shell#url_pattern())
  endif
  if match != ''
    call xolox#misc#msg#debug("shell.vim %s: Matched URL '%s' in cWORD '%s'.", g:xolox#shell#version, match, cWORD)
  else
    " Now try to match an e-mail address in <cWORD> because most filenames
    " won't contain an @-sign while e-mail addresses require it.
    let match = matchstr(cWORD, xolox#shell#mail_pattern())
    if match != ''
      call xolox#misc#msg#debug("shell.vim %s: Matched e-mail address '%s' in cWORD '%s'.", g:xolox#shell#version, match, cWORD)
    endif
  endif
  if match != ''
    call xolox#misc#open#url(match)
    return 1
  else
    call xolox#misc#msg#debug("shell.vim %s: Trying to match filename in current line ..", g:xolox#shell#version)
    " As a last resort try to match a filename at the text cursor position.
    let line = getline('.')
    let idx = col('.') - 1
    let match = matchstr(line[0 : idx], '\f*$')
    let match .= matchstr(line[idx+1 : -1], '^\f*')
    " Expand leading tilde and/or environment variables in filename?
    if match =~ '^\~' || match =~ '\$'
      let match = split(expand(match), "\n")[0]
    endif
    if match != '' && (isdirectory(match) || filereadable(match))
      call xolox#misc#msg#debug("shell.vim %s: Matched valid filename '%s' in current line ..", g:xolox#shell#version, match)
      call xolox#misc#open#file(match)
      return 1
    elseif match != ''
      call xolox#misc#msg#debug("shell.vim %s: File or directory '%s' doesn't exist.", g:xolox#shell#version, match)
    endif
  endif
endfunction

function! xolox#shell#open_with_windows_shell(location)
  if xolox#misc#os#is_win() && s:has_dll()
    let error = s:library_call('openurl', a:location)
    if error != ''
      let msg = "shell.vim %s: Failed to open '%s' with Windows shell! (error: %s)"
      throw printf(msg, g:xolox#shell#version, a:location, strtrans(xolox#misc#str#trim(error)))
    endif
  endif
endfunction

function! xolox#shell#highlight_urls() " -- highlight URLs and e-mail addresses embedded in source code comments {{{1
  " URL highlighting breaks highlighting of <a href="..."> tags in HTML.
  if exists('g:syntax_on') && &ft !~ xolox#misc#option#get('shell_hl_exclude', '^\(x|ht\)ml$')
    if &ft == 'help'
      let command = 'syntax match %s /%s/'
      let urlgroup = 'HelpURL'
      let mailgroup = 'HelpEmail'
    else
      let command = 'syntax match %s /%s/ contained containedin=.*Comment.*'
      let urlgroup = 'CommentURL'
      let mailgroup = 'CommentEmail'
    endif
    execute printf(command, urlgroup, escape(xolox#shell#url_pattern(), '/'))
    execute printf(command, mailgroup, escape(xolox#shell#mail_pattern(), '/'))
    execute 'highlight def link' urlgroup 'Underlined'
    execute 'highlight def link' mailgroup 'Underlined'
  endif
endfunction

function! xolox#shell#execute(command, synchronous, ...) " -- execute external commands asynchronously {{{1
  try
    let cmd = a:command
    let has_input = a:0 > 0
    if has_input
      let tempin = tempname()
      call writefile(type(a:1) == type([]) ? a:1 : split(a:1, "\n"), tempin)
      let cmd .= ' < ' . xolox#misc#escape#shell(tempin)
    endif
    if a:synchronous
      let tempout = tempname()
      let cmd .= ' > ' . xolox#misc#escape#shell(tempout) . ' 2>&1'
    endif
    if xolox#misc#os#is_win() && s:has_dll()
      let fn = 'execute_' . (a:synchronous ? '' : 'a') . 'synchronous'
      let cmd = &shell . ' ' . &shellcmdflag . ' ' . cmd
      call xolox#misc#msg#debug("shell.vim %s: Executing %s using compiled DLL.", g:xolox#shell#version, cmd)
      let error = s:library_call(fn, cmd)
      if error != ''
        let msg = '%s(%s) failed! (error: %s)'
        throw printf(msg, fn, strtrans(cmd), strtrans(error))
      endif
    else
      if has('unix') && !a:synchronous
        let cmd = '(' . cmd . ') &'
      endif
      call xolox#misc#msg#debug("shell.vim %s: Executing %s using system().", g:xolox#shell#version, cmd)
      call s:handle_error(cmd, system(cmd))
    endif
    if a:synchronous
      try
        return readfile(tempout)
      catch
        let msg = 'Failed to get output of command "%s"!'
        throw printf(msg, strtrans(cmd))
      endtry
    else
      return 1
    endif
  catch
    call xolox#misc#msg#warn("shell.vim %s: %s at %s", g:xolox#shell#version, v:exception, v:throwpoint)
  finally
    if exists('tempin') | call delete(tempin) | endif
    if exists('tempout') | call delete(tempout) | endif
  endtry
endfunction

function! xolox#shell#maximize(...) " -- show/hide Vim's menu, tool bar and/or tab line {{{1
  let new_state = a:0 == 0 ? !s:maximized : a:1
  if new_state && !s:maximized
    " Hide the main menu, tool bar and/or tab line. Remember what was hidden
    " so its visibility can be restored when the user leaves full-screen.
    let s:go_toggled = ''
    let fullscreen_items = xolox#misc#option#get('shell_fullscreen_items', 'mTe')
    for item in split(fullscreen_items, '.\zs')
      if &go =~# item
        let s:go_toggled .= item
        execute 'set go-=' . item
      endif
    endfor
    if fullscreen_items =~# 'e' && &stal != 0
      let s:stal_save = &stal
      set showtabline=0
    endif
    let s:maximized = 1
  elseif s:maximized && !new_state
    " Restore display of previously hidden GUI components?
    let &go .= s:go_toggled
    if exists('s:stal_save')
      let &stal = s:stal_save
      unlet s:stal_save
    endif
    unlet s:go_toggled
    let s:maximized = 0
  endif
  return s:maximized
endfunction

function! xolox#shell#fullscreen() " -- toggle Vim between normal and full-screen mode {{{1

  " When entering full-screen...
  if !s:fullscreen_enabled
    " Save the window position and size when running Windows, because my
    " dynamic link library doesn't save/restore them while "wmctrl" does.
    if xolox#misc#os#is_win()
      let [s:lines_save, s:columns_save] = [&lines, &columns]
      let [s:winpos_x_save, s:winpos_y_save] = [getwinposx(), getwinposy()]
    endif
    call xolox#shell#maximize(1)
  endif

  " Now try to toggle the real full-screen status of Vim's GUI window using a
  " custom dynamic link library on Windows or the "wmctrl" program on UNIX.
  try
    if xolox#misc#os#is_win() && s:has_dll()
      let error = s:library_call('fullscreen', !s:fullscreen_enabled)
      if error != ''
        throw "shell.dll failed with: " . error
      endif
    elseif has('unix')
      if !executable('wmctrl')
        let msg = "Full-screen on UNIX requires the `wmctrl' program!"
        throw msg . " On Debian/Ubuntu you can install it by executing `sudo apt-get install wmctrl'."
      endif
      let command = 'wmctrl -r :ACTIVE: -b toggle,fullscreen 2>&1'
      call s:handle_error(command, system(command))
    else
      throw printf(s:enoimpl, 'fullscreen', s:contact)
    endif
  catch
    call xolox#misc#msg#warn("shell.vim %s: %s at %s", g:xolox#shell#version, v:exception, v:throwpoint)
  endtry

  " When leaving full-screen...
  if s:fullscreen_enabled
    call xolox#shell#maximize(0)
    " Restore window position and size only on Windows -- I don't know why
    " but the following actually breaks when running under "wmctrl"...
    if xolox#misc#os#is_win()
      let [&lines, &columns] = [s:lines_save, s:columns_save]
      execute 'winpos' s:winpos_x_save s:winpos_y_save
      unlet s:lines_save s:columns_save s:winpos_x_save s:winpos_y_save
    endif
  endif

  " Toggle the boolean status returned by xolox#shell#is_fullscreen().
  let s:fullscreen_enabled = !s:fullscreen_enabled

  " Let the user know how to leave full-screen mode?
  if s:fullscreen_enabled
    " Take a moment to let Vim's GUI finish redrawing (:redraw is
    " useless here because it only redraws Vim's internal state).
    sleep 50 m
    call xolox#misc#msg#info("shell.vim %s: To return from full-screen type <F11> or execute :Fullscreen.", g:xolox#shell#version)
  endif

endfunction

function! xolox#shell#is_fullscreen() " -- check whether Vim is currently in full-screen mode {{{1
  return s:fullscreen_enabled
endfunction

function! xolox#shell#url_exists(url) " -- check whether a URL points to an existing resource (using Python) {{{1
  try
    " Embedding Python code in Vim scripts is always a bit awkward :-(
    " (because of the forced indentation thing Python insists on).
    let starttime = xolox#misc#timer#start()
python <<EOF

# Standard library modules.
import httplib
import urlparse

# Only loaded inside the Python interface to Vim.
import vim

# We need to define a function to enable redirection implemented through recursion.

def shell_url_exists(absolute_url, rec=0):
  assert rec <= 10
  components = urlparse.urlparse(absolute_url)
  netloc = components.netloc.split(':', 1)
  if components.scheme == 'http':
    connection = httplib.HTTPConnection(*netloc)
  elif components.scheme == 'https':
    connection = httplib.HTTPSConnection(*netloc)
  else:
    assert False, "Unsupported URL scheme"
  relative_url = urlparse.urlunparse(('', '') + components[2:])
  connection.request('HEAD', relative_url)
  response = connection.getresponse()
  if 300 <= response.status < 400:
    for name, value in response.getheaders():
      if name.lower() == 'location':
        shell_url_exists(value.strip(), rec+1)
        break
  else:
    assert 200 <= response.status < 400

shell_url_exists(vim.eval('a:url'))

EOF
    call xolox#misc#timer#stop("shell.vim %s: Took %s to verify whether %s exists (it does).", g:xolox#shell#version, starttime, a:url)
    return 1
  catch
    call xolox#misc#timer#stop("shell.vim %s: Took %s to verify whether %s exists (it doesn't).", g:xolox#shell#version, starttime, a:url)
    return 0
  endtry
endfunction

function! xolox#shell#url_pattern() " -- get the preferred/default pattern to match URLs {{{1
  return xolox#misc#option#get('shell_patt_url', '\<\w\{3,}://\(\S*\w\)\+[/?#]\?')
endfunction

function! xolox#shell#mail_pattern() " -- get the preferred/default pattern to match e-mail addresses {{{1
  return xolox#misc#option#get('shell_patt_mail', '\<\w[^@ \t\r]*\w@\w[^@ \t\r]\+\w\>')
endfunction

" Miscellaneous script-local functions. {{{1

if xolox#misc#os#is_win()

  let s:cpu_arch = has('win64') ? 'x64' : 'x86'
  let s:library = expand('<sfile>:p:h:h:h') . '\misc\shell\shell-' . s:cpu_arch . '.dll'

  function! s:library_call(fn, arg) " {{{2
    return libcall(s:library, a:fn, a:arg)
  endfunction

  function! s:has_dll() " {{{2
    try
      return s:library_call('libversion', '') == '0.3'
    catch
      return 0
    endtry
  endfunction

endif

function! s:handle_error(cmd, output) " {{{2
  if v:shell_error
    let msg = "Command %s failed!"
    if a:output =~ '^\_s*$'
      throw printf(msg, string(a:cmd))
    else
      let msg .= ' (output: %s)'
      let output = strtrans(xolox#misc#str#trim(a:output))
      throw printf(msg, string(a:cmd), )
    endif
  endif
endfunction

" vim: ts=2 sw=2 et fdm=marker
