# This is a makefile for NMAKE from the Windows SDK.

install: shell.dll
	COPY shell.dll "%USERPROFILE%\vimfiles\autoload\xolox\shell.dll"

shell.dll: shell.c
	CL /nologo /LD shell.c shell32.lib user32.lib

clean:
	DEL shell.exp shell.lib shell.obj

# vim: ff=dos
