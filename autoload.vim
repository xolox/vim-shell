" Vim auto-load script
" Author: Peter Odding <peter@peterodding.com>
" Last Change: August 30, 2010
" URL: http://peterodding.com/code/vim/shell/

if !exists('s:script')
  let s:script = expand('<sfile>:p:~')
  let s:enoimpl = "%s() hasn't been implemented on your platform! %s"
  let s:contact = "If you have suggestions, please contact the vim_dev mailing-list or peter@peterodding.com."
  let s:fullscreen_enabled = 0
endif

function! xolox#shell#open_cmd(arg) " -- implementation of the :Open command {{{1
  if a:arg !~ '\S'
    if !s:open_at_cursor()
      call xolox#shell#open_with(expand('%:p:h'))
    endif
  elseif a:arg =~ g:shell_patt_url || a:arg =~ g:shell_patt_mail
    call xolox#shell#open_url(a:arg)
  else
    let arg = fnamemodify(a:arg, ':p')
    if isdirectory(arg) || filereadable(arg)
      call xolox#shell#open_with(arg)
    else
      let msg = "%s: I don't know how to open %s!"
      echoerr printf(msg, s:script, string(a:arg))
    endif
  endif
endfunction

function! s:open_at_cursor()
  let cWORD = expand('<cWORD>')
  " Start by trying to match a URL in <cWORD> because URLs can be more-or-less
  " unambiguously distinguished from e-mail addresses and filenames.
  let match = matchstr(cWORD, g:shell_patt_url)
  if match == ''
    " Now try to match an e-mail address in <cWORD> because most filenames
    " won't contain an @-sign while e-mail addresses require it.
    let match = matchstr(cWORD, g:shell_patt_mail)
    if match == ''
      " As a last resort try to match a filename at the text cursor position.
      let line = getline('.')
      let idx = col('.') - 1
      let match = matchstr(line[0 : idx], '\f*$')
      let match .= matchstr(line[idx+1 : -1], '^\f*')
      " Expand leading tilde and/or environment variables in filename?
      if match =~ '^\~' || match =~ '\$'
        " TODO This can return multiple files?!
        let match = expand(match)
      endif
      if !isdirectory(match) && !filereadable(match)
        let match = ''
      endif
    endif
  endif
  if match != ''
    call xolox#shell#open_url(match)
    return 1
  endif
endfunction

function! xolox#shell#open_url(url) " -- open the given URL in the user's preferred web browser {{{1
  try
    let url = a:url
    if url =~ g:shell_patt_mail && url !~ '^mailto:'
      let url = 'mailto:' . url
    endif
    if s:is_windows()
      if s:has_dll()
        call s:library_call('openurl', url)
      else
        call s:execute('CMD /C START "" %s', [url])
      endif
      return 1
    elseif has('macunix')
      " I don't have OS X available to test this but since `open`
      " seems such a simple command this should be fine?
      call s:execute('open %s', [url])
      return 1
    elseif has('unix')
      if !has('gui_running') && $DISPLAY == ''
        for browser in ['lynx', 'links', 'w3m']
          if executable(browser)
            execute '!' . browser fnameescape(url)
            return 1
          endif
        endfor
        let msg = "Failed to find command-line web browser. %s"
        throw printf(msg, s:contact)
      elseif xolox#shell#open_with(url, 'firefox', 'google-chrome')
        return 1
      else
        let msg = "Failed to find graphical web browser. %s"
        throw printf(msg, s:contact)
      endif
    endif
    throw printf(s:enoimpl, 'openurl', s:contact)
  catch
    call xolox#warning("%s: %s at %s", s:script, v:exception, v:throwpoint)
  endtry
endfunction

function! xolox#shell#open_with(location, ...) " -- generic handler to open files in the user's preferred applications {{{1
  if s:is_windows()
    if s:has_dll()
      " A bit of a misnomer: openurl() in shell.dll is implemented using
      " ShellExecute() which also knows how to open files and directories.
      call s:library_call('openurl', a:location)
    else
      call s:execute('CMD /C START "" %s', [a:location])
    endif
    return 1
  else
    for handler in g:shell_open_cmds + a:000
      if executable(handler)
        let location = a:location
        if a:location !~ g:shell_patt_url && a:location !~ g:shell_patt_mail
          let location = fnamemodify(location, ':p:~')
        endif
        call xolox#message("Opening %s with %s", location, handler)
        call s:execute('%s %s', [handler, a:location])
        return 1
      endif
    endfor
  endif
endfunction

function! xolox#shell#highlight_urls() " -- highlight URLs and e-mail addresses embedded in source code comments {{{1
  if exists('g:syntax_on') && &ft !~ g:shell_hl_exclude
    if &ft == 'help'
      let command = 'syntax match %s /%s/'
      let urlgroup = 'HelpURL'
      let mailgroup = 'HelpEmail'
    else
      let command = 'syntax match %s /%s/ contained containedin=.*Comment.*'
      let urlgroup = 'CommentURL'
      let mailgroup = 'CommentEmail'
    endif
    execute printf(command, urlgroup, escape(g:shell_patt_url, '/'))
    execute printf(command, mailgroup, escape(g:shell_patt_mail, '/'))
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
      let cmd .= ' < ' . shellescape(tempin)
    endif
    if a:synchronous
      let tempout = tempname()
      let cmd .= ' > ' . shellescape(tempout) . ' 2>&1'
    endif
    if s:is_windows() && s:has_dll()
      let fn = 'execute_' . (a:synchronous ? '' : 'a') . 'synchronous'
      let cmd = ($COMSPEC != '' ? $COMSPEC : 'CMD.EXE') . ' /C ' . cmd
      let error = s:library_call(fn, cmd)
      if error != ''
        let msg = '%s: %s(%s) failed! (error: %s)'
        throw printf(msg, s:script, fn, strtrans(cmd), strtrans(error))
      endif
    else
      if has('unix') && !a:synchronous
        let cmd = '(' . cmd . ') &'
      endif
      let output = split(system(cmd), "\n")
      call s:handle_error(cmd, output)
    endif
    if a:synchronous
      if !filereadable(tempout)
        let msg = '%s: Failed to execute %s!'
        throw printf(msg, s:script, strtrans(cmd))
      endif
      return readfile(tempout)
    else
      return 1
    endif
  catch
    call xolox#warning("%s: %s at %s", s:script, v:exception, v:throwpoint)
  finally
    if exists('tempin') | call delete(tempin) | endif
    if exists('tempout') | call delete(tempout) | endif
  endtry
endfunction

function! xolox#shell#fullscreen() " -- toggle Vim between normal and full-screen mode {{{1

  " On entering full-screen hide GUI components like the main menu, tool bar
  " and tab line. Remember which components were actually hidden and should be
  " restored when leaving full-screen later.
  if !s:fullscreen_enabled
    let s:go_toggled = ''
    for item in split(g:shell_fullscreen_items, '.\zs')
      if &go =~# item
        let s:go_toggled .= item
        execute 'set go-=' . item
      endif
    endfor
    if g:shell_fullscreen_items =~# 'e' && &stal != 0
      let s:stal_save = &stal
      set showtabline=0
    endif
  endif

  " Now try to toggle the real full-screen status of Vim's GUI window using a
  " custom dynamic link library on Windows or the "wmctrl" program on UNIX.
  try
    if s:is_windows()
      if !s:has_dll()
        let msg = "The DLL library %s is missing!"
        throw printf(msg, string(s:library))
      endif
      let error = s:library_call('fullscreen', !s:fullscreen_enabled)
      if error != ''
        throw "shell.dll failed with: " . error
      endif
    elseif has('unix')
      if !executable('wmctrl')
        let msg = "Full-screen on UNIX requires the `wmctrl' program!"
        throw msg . " On Debian/Ubuntu you can install it by executing `sudo apt-get install wmctrl'."
      endif
      call s:execute('wmctrl -r %s -b toggle,fullscreen 2>&1', [':ACTIVE:'])
    else
      throw printf(s:enoimpl, 'fullscreen', s:contact)
    endif
  catch
    call xolox#warning("%s: %s at %s", s:script, v:exception, v:throwpoint)
  endtry

  " On leaving full-screen restore display of previously hidden GUI components?
  if s:fullscreen_enabled
    let &go .= s:go_toggled
    if exists('s:stal_save')
      let &stal = s:stal_save
      unlet s:stal_save
    endif
  endif

  " Toggle the boolean status returned by xolox#shell#is_fullscreen().
  let s:fullscreen_enabled = !s:fullscreen_enabled

  " Let the user know how to leave full-screen mode?
  if s:fullscreen_enabled
    sleep 50 m
    call xolox#message("To return from full-screen type <F11> or execute :Fullscreen.")
  endif

endfunction

function! xolox#shell#is_fullscreen() " -- check whether Vim is currently in full-screen mode {{{1
  return s:fullscreen_enabled
endfunction

function! xolox#shell#build_cmd(cmd, args) " -- create a command-line from a program and its escaped arguments {{{1
  if a:args == []
    return a:cmd
  else
    let args = map(copy(a:args), 'shellescape(v:val)')
    call insert(args, a:cmd, 0)
    return call('printf', args)
  endif
endfunction

" Miscellaneous script-local functions. {{{1

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
  let cmd = xolox#shell#build_cmd(a:cmd, a:args)
  let output = system(cmd)
  call s:handle_error(cmd, output)
  return output
endfunction

function! s:handle_error(cmd, output) " {{{2
  if v:shell_error
    if type(a:output) == type([])
      let output = join(a:output, "\n")
    else
      let output = a:output
    endif
    let msg = "Command %s failed!"
    if output =~ '^\_s*$'
      throw printf(msg, string(a:cmd))
    else
      let msg .= ' (output: %s)'
      throw printf(msg, string(a:cmd), strtrans(output))
    endif
  endif
endfunction

" vim: ts=2 sw=2 et fdm=marker
