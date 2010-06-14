" Vim autoload plug-in
" Maintainer: Peter Odding <peter@peterodding.com>
" Last Change: June 14, 2010
" URL: http://peterodding.com/code/vim/shell

" This Vim script enables tighter integration between Vim and its environment
" by exposing the following features to Vim scripts on supported platforms:
"
"  - Open a given URL in the user's default web browser.
"  - Execute external, non-interactive programs without flashing a command
"    prompt in front of Vim (this is only needed on the Windows platform).
"  - Toggle Vim between regular and full-screen mode (like web browsers).

let s:script = expand('<sfile>:p:~')
let s:enoimpl = "%s: %s() hasn't been implemented on your platform! %s"
let s:contact = "If you have suggestions, please contact the vim_dev mailing-list or peter@peterodding.com."

function! xolox#shell#openurl(url) " {{{1
  if s:is_windows()
    if s:has_dll()
      call s:library_call('openurl', a:url)
    else
      call s:execute('CMD /C START "" %s', [a:url])
    endif
    return 1
  elseif has('macunix')
    " I don't have OS X available to test this but since `open`
    " seems such a simple command this should be fine?
    call s:execute('open %s', [a:url])
    return 1
  elseif has('unix')
    if !has('gui_running') && $DISPLAY == ''
      for browser in ['lynx', 'links', 'w3m']
        if executable(browser)
          execute '!' . browser fnameescape(a:url)
          return 1
        endif
      endfor
      let msg = "%s: Failed to find command-line web browser. %s"
      throw printf(msg, s:script, s:contact)
    else
      for handler in ['gnome-open', 'kde-open', 'exo-open', 'xdg-open', 'firefox', 'google-chrome']
        if executable(handler)
          call s:execute('%s %s', [handler, a:url])
          return 1
        endif
      endfor
      let msg = "%s: Failed to find graphical web browser. %s"
      throw printf(msg, s:script, s:contact)
    endif
  endif
  throw printf(s:enoimpl, s:script, 'openurl', s:contact)
endfunction

function! xolox#shell#execute(command, synchronous) " {{{1
  if s:is_windows() && s:has_dll()
    let fn = 'execute_' . (a:synchronous ? '' : 'a') . 'synchronous'
    let error = s:library_call(fn, a:command)
    if error != ''
      let msg = '%s: %s(%s) failed! (error: %s)'
      throw printf(msg, s:script, fn, strtrans(a:command), strtrans(error))
    endif
  else
    let cmd = a:command
    if has('unix') && !a:synchronous
      let cmd = '(' . cmd . ') &'
    endif
    let output = system(cmd)
    call s:handle_error(cmd, output)
  endif
  return 1
endfunction

function! xolox#shell#fullscreen() " {{{1
  if s:is_windows()
    if !s:has_dll()
      let msg = "%s: The DLL library %s is missing!"
      throw printf(msg, s:script, string(s:library))
    endif
    if !exists('s:fullscreen_enabled')
      let s:fullscreen_enabled = 0
    endif
    call s:library_call('fullscreen', !s:fullscreen_enabled)
    let s:fullscreen_enabled = !s:fullscreen_enabled
    return 1
  elseif has('unix')
    if executable('wmctrl')
      for line in split(s:execute('wmctrl -l', []), "\n")
        if len(line) >= len(v:servername)
          if line[-len(v:servername):-1] == v:servername
            let window_id = matchstr(line, '^\S\+')
            break
          endif
        endif
      endfor
      if exists('window_id')
        call s:execute('wmctrl -ir %s -b toggle,fullscreen 2>&1', [window_id])
      else
        call s:execute('wmctrl -r %s -b toggle,fullscreen 2>&1', [v:servername])
      endif
      return 1
    else
      let msg = "%s: Full-screen on UNIX requires the `wmctrl' program!"
      let msg .= " On Debian/Ubuntu you can install it by executing `sudo apt-get install wmctrl'."
      throw printf(msg, s:script)
    endif
  else
    throw printf(s:enoimpl, s:script, 'fullscreen', s:contact)
  endif
  return 0
endfunction

function! xolox#shell#buildcmd(cmd, args) " {{{1
  if a:args == []
    return a:cmd
  else
    let args = map(copy(a:args), 'shellescape(v:val)')
    call insert(args, a:cmd, 0)
    return call('printf', args)
  endif
endfunction

" Supporting functions. {{{1

function! s:is_windows() " {{{2
  return has('win32') || has('win64')
endfunction

if s:is_windows()

  let s:library = expand('<sfile>:p:h') . '\shell.dll'

  function! s:library_call(fn, arg) " {{{2
    return libcall(s:library, a:fn, a:arg)
  endfunction

  function! s:find_dll_version() " {{{2
    try
      return s:library_call('libversion', '')
    catch
      let msg = "%s: Failed to load %s DLL!"
      let lib = fnamemodify(s:library, ':~')
      echohl warningmsg
      echomsg printf(msg, s:script, lib)
      echohl none
    endtry
    return '?'
  endfunction

  function! s:has_dll() " {{{2
    " Check that the DLL is available using libversion() before calling any of
    " the other functions. This is only done the first time this plug-in needs
    " to call the DLL and also makes sure the right version is loaded.
    if !exists('s:library_version')
      let s:library_version = s:find_dll_version()
    endif
    return s:library_version == '0.2'
  endfunction

endif

function! s:execute(cmd, args) " {{{2
  let cmd = xolox#shell#buildcmd(a:cmd, a:args)
  let output = system(cmd)
  call s:handle_error(cmd, output)
  return output
endfunction

function! s:handle_error(cmd, output) " {{{2
  if v:shell_error
    let msg = "%s: Command %s failed!"
    if a:output =~ '^\s*$'
      throw printf(msg, s:script, string(a:cmd))
    else
      let msg .= ' (output: %s)'
      throw printf(msg, s:script, string(a:cmd), strtrans(a:output))
    endif
  endif
endfunction
