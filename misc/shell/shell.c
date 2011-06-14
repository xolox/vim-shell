/* This is a dynamic link library for Vim on Windows that makes the following
 * features available to Vim:
 *
 *  - Open the user's preferred web browser with a given URL;
 *  - Execute external commands *without* showing a command prompt,
 *    optionally waiting for the command to finish;
 *  - Toggle Vim's full-screen state using a bit of Windows API magic.
 * 
 * If you want to compile this library yourself you need to have the Microsoft
 * Windows SDK installed, you can find a download link on the following web
 * page: http://en.wikipedia.org/wiki/Microsoft_Windows_SDK. It comes in a web
 * install and when you leave all features checked it clocks in at a few
 * gigabytes, but since we don't need any of the .NET tools you can just
 * uncheck all items mentioning .NET :-)
 *
 * Open the Windows SDK command prompt and run the following command:
 *
 *     CL /LD shell.c shell32.lib user32.lib
 *
 * This should create the dynamic link library "shell.dll" which you can call
 * from Vim using for example :call libcall('c:/shell.dll', 'fullscreen', 1).
 *
 * Happy vimming!
 *
 *  - Peter Odding <peter@peterodding.com>
 */

#define _WIN32_WINNT 0x0500 /* GetConsoleWindow() */
#define WIN32_LEAN_AND_MEAN /* but keep it simple */
#include <windows.h>
#include <shellapi.h> /* ShellExecute? */

/* Dynamic strings are returned using a static buffer to avoid memory leaks */
static char buffer[1024 * 10];

#undef MessageBox
#define MessageBox(message) MessageBoxA(NULL, message, "Vim Library", 0)

static char *GetError(void) /* {{{1 */
{
	int i;

	FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
			NULL, GetLastError(), 0, buffer, sizeof buffer, NULL);
	i = strlen(buffer);
	while (i >= 2 && isspace(buffer[i-2])) {
		buffer[i-2] = '\0';
		i--;
	}
	return buffer;
}

static char *Success(char *result) /* {{{1 */
{
	/* printf("OK\n"); */
	return result;
}

static char *Failure(char *result) /* {{{1 */
{
	/* if (result && strlen(result)) MessageBox(result); */
	return result;
}

static char *execute(char *command, int wait) /* {{{1 */
{
	STARTUPINFO si;
	PROCESS_INFORMATION pi;
	ZeroMemory(&si, sizeof(si));
	ZeroMemory(&pi, sizeof(pi));
	si.cb = sizeof(si);
	if (CreateProcess(0, command, 0, 0, 0, CREATE_NO_WINDOW, 0, 0, &si, &pi)) {
		if (wait) {
			WaitForSingleObject(pi.hProcess, INFINITE);
			/* long exit_code; */
			/* TODO: GetExitCodeProcess( pi.hProcess, &exit_code); */
			CloseHandle(pi.hProcess);
			CloseHandle(pi.hThread);
		}
		return Success(NULL);
	} else {
		return Failure(GetError());
	}
}

__declspec(dllexport)
char *execute_synchronous(char *command) /* {{{1 */
{
	return execute(command, 1);
}

__declspec(dllexport)
char *execute_asynchronous(char *command) /* {{{1 */
{
	return execute(command, 0);
}

__declspec(dllexport)
char *libversion(char *ignored) /* {{{1 */
{
	(void)ignored;
	return Success("0.2");
}

__declspec(dllexport)
char *openurl(char *path) /* {{{1 */
{
	ShellExecute(NULL, "open", path, NULL, NULL, SW_SHOWNORMAL);
	return Success(NULL);
}

__declspec(dllexport)
char *fullscreen(long enable) /* {{{1 */
{
	HWND window;
	LONG styles;
	HMONITOR monitor;
	MONITORINFO info = { sizeof info };

	if (!(window = GetForegroundWindow()))
		return Failure("Could not get handle to foreground window!");

	if (!(styles = GetWindowLong(window, GWL_STYLE)))
		return Failure("Could not query window styles!");

	if (enable) styles ^= WS_CAPTION | WS_THICKFRAME;
	else        styles |= WS_CAPTION | WS_THICKFRAME;

	if (!SetWindowLong(window, GWL_STYLE, styles))
		return Failure("Could not apply window styles!");

	if (enable) {
		if (!(monitor = MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST)))
			return Failure("Could not get handle to monitor!");
		if (!GetMonitorInfo(monitor, &info))
			return Failure("Could not get monitor information!");
		if (!SetWindowPos(window, HWND_TOP,
					info.rcMonitor.left,
					info.rcMonitor.top,
					info.rcMonitor.right - info.rcMonitor.left,
					info.rcMonitor.bottom - info.rcMonitor.top,
					SWP_SHOWWINDOW))
			return Failure("Could not resize window!");
	} else if (!SetWindowPos(window, HWND_TOP, 0, 0, 0, 0,
				SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED))
		return Failure("Could not restore window!");

	return Success(NULL);
}

__declspec(dllexport)
char *console(char *command) /* {{{1 */
{
	/* TODO: The quest to embedding a command prompt in Vim :)
	 * This doesn't quite work and I'm afraid it never will.
	 */

	HWND gvim, console;
	LONG styles;

	if (!(gvim = GetForegroundWindow()))
		return Failure("Could not get handle to foreground window");

	// destroy old console?
	if (GetConsoleWindow()) FreeConsole();

	// allocate new console
	if (!AllocConsole())
		return Failure("Could not allocate console");

	// get handle to console window
	if (!(console = GetConsoleWindow()))
		return Failure("Could not get handle to console window");

	// embed console inside foreground window
	if (!(SetParent(console, gvim)))
		return Failure("Could not embed console in Gvim window");

	if (!CreateProcess(0, command, 0, 0, 0, 0, 0, 0, 0, 0))
		return Failure("Could not create child process");

	MessageBox("Injection performed!");

	return Success(NULL);
}

/* vim: set ff=dos ts=2 sw=2 noet : */
