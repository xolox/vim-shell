# This makefile for NMAKE from the Windows SDK will compile the DLL based on
# how you configured your Windows SDK build console using SetEnv. Make sure to
# rename the compiled DLL to shell-x86.dll or shell-x64.dll when you copy it to
# the %USERPROFILE\vimfiles\autoload\xolox directory.

shell.dll: shell.c
	CL /nologo /LD shell.c shell32.lib user32.lib

clean:
	DEL shell.exp shell.lib shell.obj

# vim: ff=dos
