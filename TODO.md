 * Test the `shell.dll` library on as many configurations as possible! (different Windows versions, 32 vs. 64 bit, etc.)

 * Document how to pass standard input to shell commands using xolox#shell#execute().

 * Replace the temporary file hack with a proper silent `popen()` implementation?

 * I've [announced this plug-in](http://groups.google.com/group/vim_dev/browse_frm/thread/2cdeb5709fbfc0a0) on the vim-dev mailing list but received some criticism. So for future reference: The problem solved by `xolox#shell#execute()` really does exist, see for example the [Syntastic script page](http://www.vim.org/scripts/script.php?script_id=2736) which says: "This plugin is currently only recommended for UNIX users. It is functional on Windows, but since the syntax checking plugins shell out, the command window briefly appears whenever one is executed."
