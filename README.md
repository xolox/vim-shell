# Improved integration between <br> Vim and its environment

This plug-in aims to improve the integration between [Vim] [vim] and its environment (your operating system) by providing the following functionality:

 * The `:Fullscreen` command and `<F11>` mapping toggle Vim between normal and full-screen mode (see the [screenshots] [screenshots]). To invoke this functionality without using the `:Fullscreen` command see the `xolox#shell#fullscreen()` and `xolox#shell#is_fullscreen()` functions.

   * The `:Maximize` command and `<Control-F11>` mapping toggle Vim between normal and maximized state: They show/hide Vim's menu bar, tool bar and/or tab line without hiding the operating system task bar.

 * The `:Open` command and `<F6>` mapping know how to open file and directory names, URLs and e-mail addresses in your favorite programs (file manager, web browser, e-mail client, etc).

 * The `xolox#misc#os#exec()` function enables other Vim plug-ins (like my [easytags.vim] [easytags] plug-in) to execute external commands in the background (i.e. asynchronously) *without opening a command prompt window on Windows*.

Two [Windows DLL files] [dll] are included to perform these functions on Windows, while on UNIX external commands are used. MacVim supports full-screen out of the box (and vim-shell knows how to enable it) but is otherwise treated as UNIX.

## Installation

*Please note that the vim-shell plug-in requires my vim-misc plug-in which is separately distributed.*

Unzip the most recent ZIP archives of the [vim-shell] [download-shell] and [vim-misc] [download-misc] plug-ins inside your Vim profile directory (usually this is `~/.vim` on UNIX and `%USERPROFILE%\vimfiles` on Windows), restart Vim and execute the command `:helptags ~/.vim/doc` (use `:helptags ~\vimfiles\doc` instead on Windows).

If you prefer you can also use [Pathogen] [pathogen], [Vundle] [vundle] or a similar tool to install & update the [vim-shell] [github-shell] and [vim-misc] [github-misc] plug-ins using a local clone of the git repository.

After you've installed the plug-in and restarted Vim, the following commands will be available to you:

## Usage (commands & functions)

### The `:Maximize` command

This command toggles the visibility of Vim's main menu, tool bar and/or tab line. It's mapped to `<Control-F11>` by default, see `g:shell_mappings_enabled` if you don't like this. If you want to change which items are hidden see the `g:shell_fullscreen_items` option.

### The `:Fullscreen` command

The `:Fullscreen` command toggles Vim between normal and [full-screen mode] [screenshots]. It's mapped to `<F11>` by default, see `g:shell_mappings_enabled` if you don't like this. This command first executes `:Maximize` and then (if possible) switches Vim's [GUI window] [gui] to real full-screen mode (hiding any [taskbars, panels or docks] [taskbars]). When you leave full-screen Vim's main menu, toolbar and tabline are restored and the [GUI window] [gui] is switched back to normal mode.

Note that on UNIX this command even works inside of graphical terminal emulators like `gnome-terminal` or `xterm` (try it out!).

### The `:Open` command

The `:Open` command knows how to open files, directories, URLs and e-mail addresses. It's mapped to `<F6>` by default, see `g:shell_mappings_enabled` if you don't like this. You can provide a filename, URL or e-mail address as argument to the command or if there's a filename, URL or e-mail address under the text cursor that will be used. If both of those fail, the directory containing the current file will be opened. You can use the command as follows:

    :Open http://www.vim.org/

This will launch your preferred (or the best available) web browser. Likewise the following command will open your file manager in the directory of Vim's runtime files:

    :Open $VIMRUNTIME

Note that on UNIX if the environment variable `$DISPLAY` is empty the plug-in will fall back to a command-line web browser. Because such web browsers are executed in front of Vim you have to quit the web browser to return to Vim.

### The `:MakeWithShell` command

This command is a very simple replacement for the [:make] [] command that does not pop up a console window on Windows. It doesn't come with all of the bells and whistles that Vim's built-in make command does but it should work. It properly triggers the [QuickFixCmdPre] [] and [QuickFixCmdPost] [] events, although it does so using [:silent] [] to avoid printing two "No matching autocommands" messages.

Because Vim's [v:shell_error] [] variable is read only (which means it cannot be set by a Vim plug-in) the vim-shell plug-in defines its own variable with the exit code of the `make` process executed by `:MakeWithShell`. This variable is called `g:xolox#shell#make_exit_code`. The semantics are exactly the same as for [v:shell_error] [].

The `:MakeWithShell` command uses Vim's [quickfix window] []. To make the shell plug-in use the [location-list] [] instead you can use the command `:LMakeWithShell` instead.

### The `xolox#shell#execute_with_dll()` function

The function `xolox#shell#execute_with_dll()` is used by `xolox#misc#os#exec()` and shouldn't be called directly; instead please call `xolox#misc#os#exec()` (this is what my plug-ins do). For this reason the remainder of the following text discusses the `xolox#misc#os#exec()` function.

This function enables other Vim plug-ins to execute external commands in the background (i.e. asynchronously) *without opening a command prompt window on Windows*. For example try to execute the following command on Windows ([vimrun.exe] [vimrun] is only included with Vim for Windows because it isn't needed on other platforms):

    :call xolox#misc#os#exec({'command': 'vimrun', 'async': 1})

Immediately after executing this command Vim will respond to input again because `xolox#misc#os#exec()` doesn't wait for the external command to finish when the 'async' argument is true (1). In addition no command prompt window will be shown which means [vimrun.exe] [vimrun] is running completely invisible in the background.

The function returns a dictionary of return values. In asynchronous mode the dictionary is empty. In synchronous mode it contains the following key/value pairs:

    :echo xolox#misc#os#exec({'command': 'echo "this is stdout" && echo "this is stderr" >&2 && exit 42', 'check': 0})
    {'exit_code': 42, 'stdout': ['this is stdout'], 'stderr': ['this is stderr']}

If you want to verify that this function works as described, execute the command mentioning `vimrun` above, open the Windows task manager by pressing `Control-Shift-Escape` and check that the process `vimrun.exe` is listed in the processes tab. If you don't see the problem this is solving, try executing [vimrun.exe] [vimrun] using Vim's built-in [system()] [system] function instead:

    :call system('vimrun')

Vim will be completely unresponsive until you "press any key to continue" in the command prompt window that's running [vimrun.exe] [vimrun]. Of course the [system()] [system] function should only be used with non-interactive programs (the documentation says as much) but the point is to simulate an external command that takes a while to finish and blocks Vim while doing so.

Note that on Windows this function uses Vim's ['shell'] [sh_opt] and ['shellcmdflag'] [shcf_opt] options to compose the command line passed to the DLL.

### The `xolox#shell#fullscreen()` function

Call this function to toggle Vim's full screen status. The `:Fullscreen` command is just a shorter way to call this function.

### The `xolox#shell#is_fullscreen()` function

Call this function to determine whether Vim is in full screen mode. My [session.vim plug-in] [vim-session] uses this to persist full screen mode.

### The `g:shell_fullscreen_items` option

This variable is a string containing any combination of the following characters:

 * `m`: Hide the [main menu] [go-m] when switching to full-screen;
 * `T`: Hide the [toolbar] [go-T] when switching to full-screen;
 * `e`: Hide the [tabline] [go-e] when switching to full-screen (this also toggles the [showtabline option] [stal]).

By default all the above items are hidden in full-screen mode. You can also set the buffer local variable `b:shell_fullscreen_items` to change these settings for specific buffers.

### The `g:shell_fullscreen_always_on_top` option

On Windows the `:Fullscreen` command sets the Vim window to "always on top". Some people don't like this which is why this option was added. Its default value is true (1) so to disable the "always on top" feature you would add this to your [vimrc script] [vimrc]:

    :let g:shell_fullscreen_always_on_top = 0

### The `g:shell_fullscreen_message` option

When you enter full screen the plug-in shows a Vim message explaining how to leave full screen. If you don't want to see this message you can set this option to false (0).

### The `g:shell_mappings_enabled` option

If you don't like the default mappings for the `:Open` and `:Fullscreen` commands then add the following to your [vimrc script] [vimrc]:

    :let g:shell_mappings_enabled = 0

Since no mappings will be defined now you can add something like the following to your [vimrc script] [vimrc]:

    :inoremap <Leader>fs <C-o>:Fullscreen<CR>
    :nnoremap <Leader>fs :Fullscreen<CR>
    :inoremap <Leader>op <C-o>:Open<CR>
    :nnoremap <Leader>op :Open<CR>

### The `g:shell_verify_urls` option

When you use the `:Open` command or the `<F6>` mapping to open the URL under the text cursor, the shell plug-in uses a regular expression to guess where the URL starts and ends. This works 99% percent of the time but it can break, because in this process the shell plug-in will strip trailing punctuation characters like dots (because they were likely not intended to be included in the URL).

If you actually deal with URLs that include significant trailing punctuation and your Vim is compiled with Python support you can enable the option `g:shell_verify_urls` (by setting it to 1 in your [vimrc script] [vimrc]). When you do this the plug-in will perform an HTTP HEAD request on the URL without stripping trailing punctuation. If the request returns an HTTP status code that indicates some form of success (the status code is at least 200 and less than 400) the URL including trailing punctuation is opened. If the HEAD request fails the plug-in will try again without trailing punctuation.

### The `g:shell_use_dll` option

If you set this to false (0) the DDL is never used. This is very useful during testing :-).

## Background

Vim has a limited ability to call external libraries using the Vim script function [libcall()] [libcall]. A few years ago when I was still using Windows a lot I created a [Windows DLL] [dll] that could be used with [libcall()] [libcall] to toggle [Vim] [vim]'s GUI window between regular and full-screen mode. I also added a few other useful functions, e.g. `openurl()` to launch the default web browser and `execute()` which works like Vim's [system()] [system] function but doesn't wait for the process to finish and doesn't show a command prompt.

Since then I switched to Linux and didn't look back, which meant the DLL sat in my `~/.vim/etc/` waiting to be revived. Now that I've published my [easytags.vim] [easytags] plug-in and put a lot of effort into making it Windows compatible, the `execute()` function from the DLL would be very useful to run [Exuberant Ctags] [ctags] in the background without stealing Vim's focus by opening a command prompt window. This is why I've decided to release the DLL. Because I switched to Linux I've also added an autoload script that wraps the DLL on Windows and calls out to external programs such as `wmctrl`, `gnome-open`, `kde-open`, and others on UNIX.

## Other full-screen implementations

After publishing this plug-in I found that the Vim plug-ins [VimTweak] [vimtweak] and [gvimfullscreen_win32] [gvimfullscreen_win32] also implement full-screen on Windows using a similar approach as my plug-in. I prefer the effect of my plug-in because it seems to hide window decorations more effectively. Also note that my plug-in was developed independently of the other two.

## Contact

If you have questions, bug reports, suggestions, etc. the author can be contacted at <peter@peterodding.com>. The latest version is available at <http://peterodding.com/code/vim/shell/> and <http://github.com/xolox/vim-shell>. If you like the plug-in please vote for it on [Vim Online] [vim_scripts_entry].

## License

This software is licensed under the [MIT license] [mit].
© 2014 Peter Odding &lt;<peter@peterodding.com>&gt;.


[:make]: http://vimdoc.sourceforge.net/htmldoc/quickfix.html#:make
[:silent]: http://vimdoc.sourceforge.net/htmldoc/various.html#:silent
[ctags]: http://en.wikipedia.org/wiki/Ctags
[dll]: http://en.wikipedia.org/wiki/Dynamic-link_library
[download-misc]: http://peterodding.com/code/vim/downloads/misc.zip
[download-shell]: http://peterodding.com/code/vim/downloads/shell.zip
[easytags]: http://peterodding.com/code/vim/easytags/
[github-misc]: http://github.com/xolox/vim-misc
[github-shell]: http://github.com/xolox/vim-shell
[go-e]: http://vimdoc.sourceforge.net/htmldoc/options.html#%27go-e%27
[go-m]: http://vimdoc.sourceforge.net/htmldoc/options.html#%27go-m%27
[go-T]: http://vimdoc.sourceforge.net/htmldoc/options.html#%27go-T%27
[gui]: http://vimdoc.sourceforge.net/htmldoc/gui.html#GUI
[gvimfullscreen_win32]: http://www.vim.org/scripts/script.php?script_id=2596
[libcall]: http://vimdoc.sourceforge.net/htmldoc/eval.html#libcall()
[location-list]: http://vimdoc.sourceforge.net/htmldoc/quickfix.html#location-list
[mit]: http://en.wikipedia.org/wiki/MIT_License
[pathogen]: http://www.vim.org/scripts/script.php?script_id=2332
[quickfix window]: http://vimdoc.sourceforge.net/htmldoc/quickfix.html#quickfix
[QuickFixCmdPost]: http://vimdoc.sourceforge.net/htmldoc/autocmd.html#QuickFixCmdPost
[QuickFixCmdPre]: http://vimdoc.sourceforge.net/htmldoc/autocmd.html#QuickFixCmdPre
[screenshots]: http://peterodding.com/code/vim/shell/screenshots/
[sh_opt]: http://vimdoc.sourceforge.net/htmldoc/options.html#%27shell%27
[shcf_opt]: http://vimdoc.sourceforge.net/htmldoc/options.html#%27shellcmdflag%27
[stal]: http://vimdoc.sourceforge.net/htmldoc/options.html#%27showtabline%27
[system]: http://vimdoc.sourceforge.net/htmldoc/eval.html#system()
[taskbars]: http://en.wikipedia.org/wiki/Taskbar
[v:shell_error]: http://vimdoc.sourceforge.net/htmldoc/eval.html#v:shell_error
[vim-session]: http://peterodding.com/code/vim/session/
[vim]: http://www.vim.org/
[vim_scripts_entry]: http://www.vim.org/scripts/script.php?script_id=3123
[vimrc]: http://vimdoc.sourceforge.net/htmldoc/starting.html#vimrc
[vimrun]: http://vimdoc.sourceforge.net/htmldoc/gui_w32.html#win32-vimrun
[vimtweak]: http://www.vim.org/scripts/script.php?script_id=687
[vundle]: https://github.com/gmarik/vundle
