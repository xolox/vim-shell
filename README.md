# Improved integration between <br> Vim and its environment

This plug-in aims to improve the integration between [Vim][vim] and its environment (your operating system) by providing the following functionality:

 * The `:Fullscreen` command and `<F11>` mapping toggle Vim between normal and full-screen mode (see the [screenshots](http://peterodding.com/code/vim/shell/screenshots/)). To invoke this functionality without using the `:Fullscreen` command see the `xolox#shell#fullscreen()` and `xolox#shell#is_fullscreen()` functions.

 * The `:Open` command and `<F6>` mapping know how to open file and directory names, URLs and e-mail addresses in your favorite programs (file manager, web browser, e-mail client, etc). To invoke this functionality without using the `:Open` command see my [open.vim](http://peterodding.com/code/vim/open-associated-programs/) plug-in, which was split off from `shell.vim` so that other Vim plug-ins can bundle it without bringing in all the other crap :-).

 * The `xolox#shell#execute()` function enables other Vim plug-ins (like my [easytags.vim] [easytags] plug-in) to execute external commands in the background (i.e. asynchronously) *without opening a command prompt window on Windows*.

Two [Windows DLL files][dll] are included to perform these functions on Windows, while on UNIX external commands are used.

## Usage

The below paragraphs document the functionality in the `shell.vim` plug-in. I'd be very grateful if people would test the plug-in in different environments and report their results by contacting the [vim-dev](http://vimdoc.sourceforge.net/htmldoc/intro.html#vim-dev) mailing-list or e-mailing me directly at <peter@peterodding.com>. You can test the plug-in by unpacking the [ZIP archive from www.vim.org][download] in the `%USERPROFILE%\vimfiles` directory (on Windows) or the `~/.vim/` directory (on UNIX), restarting Vim and checking whether the commands below work as documented.

### The `:Fullscreen` command

The `:Fullscreen` command toggles Vim between normal and [full-screen mode](http://peterodding.com/code/vim/shell/screenshots/). It's mapped to `<F11>` by default, see `g:shell_mappings_enabled` if you don't like this.

When you enter full-screen mode the main menu, toolbar and tabline are all hidden (see `g:shell_fullscreen_items` if you want to change this) and when possible Vim's [GUI window] [gui] is switched to real full-screen mode (hiding any [taskbars, panels or docks](http://en.wikipedia.org/wiki/Taskbar)). When you leave full-screen Vim's main menu, toolbar and tabline are restored and the [GUI window] [gui] is switched back to normal mode.

Note that on UNIX this command even works inside of graphical terminal emulators like `gnome-terminal` or `xterm` (try it out!).

### The `:Open` command

The `:Open` command knows how to open files, directories, URLs and e-mail addresses. It's mapped to `<F6>` by default, see `g:shell_mappings_enabled` if you don't like this. You can provide a filename, URL or e-mail address as argument to the command or if there's a filename, URL or e-mail address under the text cursor that will be used. If both of those fail, the directory containing the current file will be opened. You can use the command as follows:

    :Open http://www.vim.org/

This will launch your preferred (or the best available) web browser. Likewise the following command will open your file manager in the directory of Vim's runtime files:

    :Open $VIMRUNTIME

Note that on UNIX if the environment variable `$DISPLAY` is empty the plug-in will fall back to a command-line web browser. Because such web browsers are executed in front of Vim you have to quit the web browser to return to Vim.

### The `xolox#shell#execute()` function

This function enables other Vim plug-ins to execute external commands in the background (i.e. asynchronously) *without opening a command prompt window on Windows*. For example try to execute the following command on Windows ([vimrun.exe][vimrun] is only included with Vim for Windows because it isn't needed on other platforms):

    :call xolox#shell#execute('vimrun', 0)

Immediately after executing this command Vim will respond to input again because `xolox#shell#execute()` doesn't wait for the external command to finish when the second argument is false (0). In addition no command prompt window will be shown which means [vimrun.exe][vimrun] is running completely invisible in the background. When the second argument is true (1) the output of the command will be returned as a list of lines, otherwise true (1) is returned unless an error occurred, in which case false (0) is returned.

If you want to verify that this function works as described, open the Windows task manager by pressing `Control-Shift-Escape` and check that the process `vimrun.exe` is listed in the processes tab. If you don't see the problem this is solving, try executing [vimrun.exe][vimrun] using Vim's built-in [system()][system] function instead:

    :call system('vimrun')

Vim will be completely unresponsive until you "press any key to continue" in the command prompt window that's running [vimrun.exe][vimrun]. Now of course the [system()][system] function should only be used with non-interactive programs (the documentation says as much) but my point was to simulate an external command that takes a while to finish and blocks Vim while doing so.

Note that on Windows this function uses Vim's ['shell'][sh_opt] and ['shellcmdflag'][shcf_opt] options to compose the command line passed to the DLL.

### The `g:shell_fullscreen_items` option

This variable is a string containing any combination of the following characters:

 * `m`: Hide the [main menu](http://vimdoc.sourceforge.net/htmldoc/options.html#%27go-m%27) when switching to full-screen;
 * `T`: Hide the [toolbar](http://vimdoc.sourceforge.net/htmldoc/options.html#%27go-T%27) when switching to full-screen;
 * `e`: Hide the [tabline](http://vimdoc.sourceforge.net/htmldoc/options.html#%27go-e%27) when switching to full-screen (this also toggles the [showtabline option](http://vimdoc.sourceforge.net/htmldoc/options.html#%27showtabline%27)).

By default all the above items are hidden in full-screen mode.

### The `g:shell_mappings_enabled` option

If you don't like the default mappings for the `:Open` and `:Fullscreen` commands then add the following to your [vimrc script] [vimrc]:

    :let g:shell_mappings_enabled = 0

Since no mappings will be defined now you can add something like the following to your [vimrc script] [vimrc]:

    :inoremap <Leader>fs <C-o>:Fullscreen<CR>
    :nnoremap <Leader>fs :Fullscreen<CR>
    :inoremap <Leader>op <C-o>:Open<CR>
    :nnoremap <Leader>op :Open<CR>

## Background

Vim has a limited ability to call external libraries using the Vim script function [libcall()][libcall]. A few years ago when I was still using Windows a lot I created a [Windows DLL][dll] that could be used with [libcall()][libcall] to toggle [Vim][vim]'s GUI window between regular and full-screen mode. I also added a few other useful functions, e.g. `openurl()` to launch the default web browser and `execute()` which works like Vim's [system()][system] function but doesn't wait for the process to finish and doesn't show a command prompt.

Since then I switched to Linux and didn't look back, which meant the DLL sat in my `~/.vim/etc/` waiting to be revived. Now that I've published my [easytags.vim][easytags] plug-in and put a lot of effort into making it Windows compatible, the `execute()` function from the DLL would be very useful to run [Exuberant Ctags][ctags] in the background without stealing Vim's focus by opening a command prompt window. This is why I've decided to release the DLL. Because I switched to Linux I've also added an autoload script that wraps the DLL on Windows and calls out to external programs such as `wmctrl`, `gnome-open`, `kde-open`, and others on UNIX.

Before I go ahead and bundle the DLL files with my [easytags.vim][easytags] plug-in I need to make sure they're compatible with as many Windows Vim installations out there as possible, e.g. XP/Vista/7, different service packs, 32/64 bits, etc. I've uploaded a [ZIP archive including two compiled DLL files][download] to the [Vim scripts page][vim_scripts_entry] for this plug-in (build using the latest Windows SDK but targeting Windows XP x86/x64 DEBUG, should also work on Vista/7) and the source code is available in the [GitHub repository](http://github.com/xolox/vim-shell) (see the `NMAKE` [makefile](http://github.com/xolox/vim-shell/blob/master/dll/Makefile) for compile instructions).

## Other full-screen implementations

After publishing this plug-in I found that the Vim plug-ins [VimTweak](http://www.vim.org/scripts/script.php?script_id=687) and [gvimfullscreen_win32](http://www.vim.org/scripts/script.php?script_id=2596) also implement full-screen on Windows using a similar approach as my plug-in. I prefer the effect of my plug-in because it seems to hide window decorations more effectively. Also note that my plug-in was developed independently of the other two.

## Contact

If you have questions, bug reports, suggestions, etc. the author can be contacted at <peter@peterodding.com>. The latest version is available at <http://peterodding.com/code/vim/shell/> and <http://github.com/xolox/vim-shell>. If you like the plug-in please vote for it on [Vim Online] [vim_scripts_entry].

## License

This software is licensed under the [MIT license](http://en.wikipedia.org/wiki/MIT_License).  
© 2011 Peter Odding &lt;<peter@peterodding.com>&gt;.


[ctags]: http://en.wikipedia.org/wiki/Ctags
[dll]: http://en.wikipedia.org/wiki/Dynamic-link_library
[download]: http://peterodding.com/code/vim/downloads/shell.zip
[easytags]: http://peterodding.com/code/vim/easytags/
[gui]: http://vimdoc.sourceforge.net/htmldoc/gui.html#GUI
[libcall]: http://vimdoc.sourceforge.net/htmldoc/eval.html#libcall()
[sh_opt]: http://vimdoc.sourceforge.net/htmldoc/options.html#%27shell%27
[shcf_opt]: http://vimdoc.sourceforge.net/htmldoc/options.html#%27shellcmdflag%27
[system]: http://vimdoc.sourceforge.net/htmldoc/eval.html#system()
[vim]: http://www.vim.org/
[vim_scripts_entry]: http://www.vim.org/scripts/script.php?script_id=3123
[vimrc]: http://vimdoc.sourceforge.net/htmldoc/starting.html#vimrc
[vimrun]: http://vimdoc.sourceforge.net/htmldoc/gui_w32.html#win32-vimrun
