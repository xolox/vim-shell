# Improved integration between <br> Vim and its environment

This plug-in aims to improve the integration between [Vim][vim] and its
environment by providing functions to switch to full-screen, open URLs in the
user's default web browser and execute external commands in the background
without opening a command prompt window. A DLL is included to perform these
things on Windows, while on UNIX external commands are used.

## Background

A few years ago when I was still using Windows I created a `libcall()`
compatible [DLL][dll] to toggle [Vim][vim]'s GUI window between regular and
full-screen mode. I also added a few other useful functions, e.g. `openurl()`
to launch the default web browser and `execute()` which works like Vim's
`system()` function but doesn't wait for the process to finish and doesn't open
a command prompt.

Since then I switched to Linux and didn't look back, which meant the DLL sat in
my `~/.vim/etc/` waiting to be revived. Now that I've published my
[easytags.vim][easytags] plug-in and put a lot of effort into making it
Windows compatible, the `execute()` function from the DLL would be very
useful to run [Exuberant Ctags][ctags] in the background without stealing Vim's
focus by opening a command prompt window. This is why I've decided to release
the DLL. Because I switched to Linux I've also added an autoload script that
wraps the DLL on Windows and calls out to external programs on UNIX (using
`wmctrl`, `gnome-open`, `kde-open`, etc.)

Before I go ahead and bundle the DLL with the `easytags.vim` plug-in I need to
make sure that the DLL is compatible with as many Windows Vim installations out
there as possible, e.g. XP/Vista/7, different service packs, 32/64 bits, etc.
and I don't know where to start! I've uploaded a [ZIP archive including a
compiled DLL][download] to the [Vim scripts page][vim_scripts_entry] for this
plug-in (build using the latest Windows SDK but targeting Windows XP x86 DEBUG,
should also work on Vista/7) and the source code is available in the [GitHub
repository] [github] (see the `NMAKE` [makefile][makefile] for compile
instructions).

## Testing the plug-in

I'd be very grateful if people would test the plug-in in different environments
and report their results by contacting the `vim_dev` mailing-list or e-mailing
me directly at <peter@peterodding.com>. You can test the DLL by unpacking the
[ZIP archive from www.vim.org][download] in the `%USERPROFILE%\vimfiles`
directory (on Windows) or the `~/.vim/` directory (on UNIX), restarting Vim and
testing the three functions as follows from inside Vim:

1. Execute the following command:

        :call xolox#shell#openurl('http://www.vim.org/')

   Does this open your preferred (or best available) web browser? On UNIX if
   the environment variable `$DISPLAY` is empty the plug-in will switch to a
   command-line browser.

2. (Windows only) Execute the following command:

        :call xolox#shell#execute('notepad')

   Does this start Notepad without blocking Vim's window and without opening a
   command prompt window to run the command?

3. In graphical Vim execute the following command:

        :call xolox#shell#fullscreen()

   Is Vim's GUI window properly switched to full-screen mode? If so you can
   return to normal mode by calling the function again. If you're stuck in
   full-screen Vim, save your existing buffers and press `Alt-F4`, that should
   always work.

## Contact

If you have questions, bug reports, suggestions, etc. the author can be
contacted at <peter@peterodding.com>. The latest version is available
at <http://peterodding.com/code/vim/shell> and <http://github.com/xolox/vim-shell>.
If you like the plug-in please vote for it on [www.vim.org] [vim_scripts_entry].

## License

This software is licensed under the [MIT license] [mit_license].  
© 2010 Peter Odding &lt;<peter@peterodding.com>&gt;.


[ctags]: http://en.wikipedia.org/wiki/Ctags
[dll]: http://en.wikipedia.org/wiki/Dynamic-link_library
[download]: http://peterodding.com/code/vim/download.php?script=shell
[easytags]: http://www.vim.org/scripts/script.php?script_id=3114
[github]: http://github.com/xolox/vim-shell
[makefile]: http://github.com/xolox/vim-shell/blob/master/dll/Makefile
[mit_license]: http://en.wikipedia.org/wiki/MIT_License
[vim]: http://www.vim.org/
[vim_scripts_entry]: http://www.vim.org/scripts/script.php?script_id=3123
