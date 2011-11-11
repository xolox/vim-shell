:: This Windows batch script compiles the Windows DLL for the
:: shell.vim plug-in for the x86 and x64 processor architectures.

:: Build shell-x86.dll.
CALL SETENV /Release /x86 /xp
CL /nologo /Wall /LD shell.c /link /out:shell-x86.dll shell32.lib user32.lib
DEL shell.exp shell.lib shell.obj

:: Build shell-x64.dll.
CALL SETENV /Release /x64 /xp
CL /nologo /Wall /LD shell.c /link /out:shell-x64.dll shell32.lib user32.lib
DEL shell.exp shell.lib shell.obj
