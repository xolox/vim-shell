" Vim auto-load script
" Author: Peter Odding <peter@peterodding.com>
" Last Change: July 7, 2014
" URL: http://peterodding.com/code/vim/shell/

let g:xolox#shell#version = '0.13.6'

if !exists('s:fullscreen_enabled')
  let s:enoimpl = "%s() hasn't been implemented on your platform! %s"
  let s:contact = "If you have suggestions, please contact peter@peterodding.com."
  let s:fullscreen_enabled = 0
  let s:maximized = 0
endif

function! xolox#shell#open_cmd(arg) " {{{1
  " Implementation of the :Open command.
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

function! xolox#shell#open_with_windows_shell(location) " {{{1
  " Open a location using the compiled DLL.
  if xolox#shell#can_use_dll()
    let error = s:library_call('openurl', a:location)
    if error != ''
      let msg = "shell.vim %s: Failed to open '%s' with Windows shell! (error: %s)"
      throw printf(msg, g:xolox#shell#version, a:location, strtrans(xolox#misc#str#trim(error)))
    endif
  endif
endfunction

function! xolox#shell#highlight_urls() " {{{1
  " Highlight URLs and e-mail addresses embedded in source code comments.
  " URL highlighting breaks highlighting of <a href="..."> tags in HTML.
  if exists('g:syntax_on') && &ft !~ xolox#misc#option#get('shell_hl_exclude', '^\(x|ht\)ml$')
    if &ft == 'help'
      let command = 'syntax match %s /%s/'
      let urlgroup = 'HelpURL'
      let mailgroup = 'HelpEmail'
    else
      let command = 'syntax match %s /%s/ contained containedin=.*Comment.*,.*String.*'
      let urlgroup = 'CommentURL'
      let mailgroup = 'CommentEmail'
    endif
    execute printf(command, urlgroup, escape(xolox#shell#url_pattern(), '/'))
    execute printf(command, mailgroup, escape(xolox#shell#mail_pattern(), '/'))
    execute 'highlight def link' urlgroup 'Underlined'
    execute 'highlight def link' mailgroup 'Underlined'
  endif
endfunction

function! xolox#shell#execute_with_dll(cmd, async) " {{{1
  " Execute external commands on Windows using the compiled DLL.
  let fn = 'execute_' . (a:async ? 'a' : '') . 'synchronous'
  " Command line parsing on Windows is batshit insane. I intended to define
  " exactly how it happens here, but the Microsoft documentation can't even
  " explain it properly, so I won't bother either. Suffice to say that the
  " outer double quotes with unescaped double quotes in between are
  " intentional... Here's a small excerpt from "help cmd":
  "
  "   Otherwise, old behavior is to see if the first character is a quote
  "   character and if so, strip the leading character and remove the last
  "   quote character on the command line, preserving any text after the last
  "   quote character.
  "
  let cmd = printf('cmd.exe /c "%s"', a:cmd)
  call xolox#misc#msg#debug("shell.vim %s: Executing external command: %s", g:xolox#shell#version, cmd)
  let result = s:library_call(fn, cmd)
  if result =~ '^exit_code=\d\+$'
    return matchstr(result, '^exit_code=\zs\d\+$') + 0
  elseif result =~ '\S'
    let msg = printf('%s(%s) failed!', fn, string(cmd))
    if result =~ '\S'
      let msg .= ' (output: ' . xolox#misc#str#trim(result) . ')'
    endif
    throw msg
  endif
endfunction

function! xolox#shell#make(mode, bang, args) " {{{1
  " Run :make silent (without a console window).
  let command = &makeprg
  if a:args =~ '\S'
    let command .= ' ' . a:args
  endif
  call xolox#misc#msg#info("shell.vim %s: Running make command: %s", g:xolox#shell#version, command)
  if a:bang == '!'
    execute printf('%sgetexpr s:make_cmd(a:mode, command)', a:mode)
  else
    execute printf('%sexpr s:make_cmd(a:mode, command)', a:mode)
  endif
  execute a:mode . 'window'
endfunction

function! s:make_cmd(mode, command)
  let event = (a:mode == 'l') ? 'lmake' : 'make'
  execute 'silent doautocmd QuickFixCmdPre' event
  let command = a:command . ' 2>&1'
  let result = xolox#misc#os#exec({'command': command, 'check': 0})
  let g:xolox#shell#make_exit_code = result['exit_code']
  execute 'silent doautocmd QuickFixCmdPost' event
  return join(result['stdout'], "\n")
endfunction

if !exists('g:xolox#shell#make_exit_code')
  let g:xolox#shell#make_exit_code = 0
endif

function! xolox#shell#maximize(...) " {{{1
  " Show/hide Vim's menu, tool bar and/or tab line.
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

function! xolox#shell#fullscreen() " {{{1
  " Toggle Vim between normal and full-screen mode.

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
    if xolox#shell#can_use_dll()
      let options = s:fullscreen_enabled ? 'disable' : 'enable'
      if g:shell_fullscreen_always_on_top
        let options .= ', always on top'
      endif
      let error = s:library_call('fullscreen', options)
      if error != ''
        throw "shell.dll failed with: " . error
      endif
    elseif has('macunix') && has('gui')
      if !s:fullscreen_enabled
        set fullscreen
      else
        set nofullscreen
      endif
    elseif has('unix')
      if !executable('wmctrl')
        let msg = "Full-screen on UNIX requires the `wmctrl' program!"
        throw msg . " On Debian/Ubuntu you can install it by executing `sudo apt-get install wmctrl'."
      endif
      let command = 'wmctrl -r :ACTIVE: -b toggle,fullscreen 2>&1'
      let output = system(command)
      if v:shell_error
        let msg = "Command %s failed!"
        if a:output =~ '^\_s*$'
          throw printf(msg, string(a:cmd))
        else
          let msg .= ' (output: %s)'
          let output = strtrans(xolox#misc#str#trim(a:output))
          throw printf(msg, string(a:cmd), output)
        endif
      endif
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
  if s:fullscreen_enabled && g:shell_fullscreen_message
    " Take a moment to let Vim's GUI finish redrawing (:redraw is
    " useless here because it only redraws Vim's internal state).
    sleep 50 m
    call xolox#misc#msg#info("shell.vim %s: To return from full-screen type <F11> or execute :Fullscreen.", g:xolox#shell#version)
  endif

endfunction

function! xolox#shell#is_fullscreen() " {{{1
  " Check whether Vim is currently in full-screen mode.
  return s:fullscreen_enabled
endfunction

function! xolox#shell#persist_fullscreen() " {{{1
  " Return Vim commands needed to restore Vim's full-screen state.
  let commands = []
  if xolox#shell#is_fullscreen()
    " The vim-session plug-in persists and restores Vim's &guioptions while
    " the :Fullscreen command also manipulates &guioptions. This can cause
    " several weird interactions. To avoid this, we do some trickery here.
    call add(commands, "let &guioptions = " . string(&guioptions . s:go_toggled))
    if exists('s:stal_save')
      call add(commands, "let &stal = " . s:stal_save)
    endif
    call add(commands, "call xolox#shell#fullscreen()")
  endif
  return commands
endfunction

function! xolox#shell#url_exists(url) " {{{1
  " Check whether a URL points to an existing resource (using Python).
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

function! xolox#shell#url_pattern() " {{{1
  " Get the preferred/default pattern to match URLs.
  return xolox#misc#option#get('shell_patt_url', '\<\w\{3,}://\(\(\S\&[^"]\)*\w\)\+[/?#]\?')
endfunction

function! xolox#shell#mail_pattern() " {{{1
  " Get the preferred/default pattern to match e-mail addresses.
  return xolox#misc#option#get('shell_patt_mail', '\<\w[^@ \t\r<>]*\w@\w[^@ \t\r<>]\+\w\>')
endfunction

function! xolox#shell#can_use_dll() " {{{1
  " Check whether the compiled DLL is usable in the current environment.
  if xolox#misc#os#is_win()
    try
      call xolox#misc#msg#debug("shell.vim %s: Checking if compiled DDL is supported ..", g:xolox#shell#version)
      if !xolox#misc#option#get('shell_use_dll', 1)
        call xolox#misc#msg#debug("shell.vim %s: Use of DDL is disabled using 'g:shell_use_dll'.", g:xolox#shell#version)
        return 0
      endif
      let expected_version = '0.5'
      let actual_version = s:library_call('libversion', '')
      if actual_version == expected_version
        call xolox#misc#msg#debug("shell.vim %s: Yes the DDL works. Good for you! :-)", g:xolox#shell#version)
        return 1
      endif
      call xolox#misc#msg#debug("shell.vim %s: The DDL works but reports version %s while I was expecting %s!", g:xolox#shell#version, string(actual_version), string(expected_version))
    catch
      call xolox#misc#msg#debug("shell.vim %s: Looks like the DDL is not working! (Vim raised an exception: %s)", g:xolox#shell#version, v:exception)
      return 0
    endtry
  endif
endfunction

" s:library_call() - Only defined on Windows. {{{1

if xolox#misc#os#is_win()

  let s:cpu_arch = has('win64') ? 'x64' : 'x86'
  let s:library = expand('<sfile>:p:h:h:h') . '\misc\shell\shell-' . s:cpu_arch . '.dll'

  function! s:library_call(fn, arg)
    let starttime = xolox#misc#timer#start()
    let result = libcall(s:library, a:fn, a:arg)
    let friendly_result = empty(result) ? '(empty string)' : printf('string %s', string(result))
    call xolox#misc#timer#stop("shell.vim %s: Called function %s() in DLL %s, returning %s in %s.", g:xolox#shell#version, a:fn, s:library, friendly_result, starttime)
    return result
  endfunction

endif

" vim: ts=2 sw=2 et fdm=marker
