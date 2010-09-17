# To-do list

 * Test the `shell.dll` library on as many configurations as possible! (different Windows versions, 32 vs. 64 bit, etc.)

 * **Bug:** On Windows when I enter full-screen for the 1st time it works and I can leave full-screen. But when I then try to enter full-screen a second time (without changing Vim's window state in any way) then it fails to actually toggle the full-screen state on!  
   **Update:** This might just be a redraw bug in VirtualBox after all?! Vim does switch to full-screen

 * Document how to pass standard input to shell commands using xolox#shell#execute().

 * Replace the temporary file hack with a proper silent `popen()` implementation?

 * I've [announced this plug-in](http://groups.google.com/group/vim_dev/browse_frm/thread/2cdeb5709fbfc0a0) on the vim-dev mailing list but received some criticism. So for future reference: The problem solved by `xolox#shell#execute()` really does exist, see for example the [Syntastic script page](http://www.vim.org/scripts/script.php?script_id=2736) which says: "This plugin is currently only recommended for UNIX users. It is functional on Windows, but since the syntax checking plugins shell out, the command window briefly appears whenever one is executed."
