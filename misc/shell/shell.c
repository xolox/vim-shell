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
 * from Vim using for example :call libcall('c:/shell.dll', 'fullscreen', 'enable').
 *
 * Happy Vimming!
 *
 *  - Peter Odding <peter@peterodding.com>
 */

#define _WIN32_WINNT 0x0500 /* GetConsoleWindow() */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <shellapi.h> /* ShellExecute? */

/* Dynamic strings are returned using static buffers to avoid memory leaks. */
static char message_buffer[1024 * 10];
static char rv_buffer[512];

#undef MessageBox
#define MessageBox(message) MessageBoxA(NULL, message, "Vim Library", 0)

static const char *GetError(void) /* {{{1 */
{
	size_t i;

	FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
			NULL, GetLastError(), 0, message_buffer, sizeof message_buffer, NULL);
	i = strlen(message_buffer);
	while (i >= 2 && isspace(message_buffer[i-2])) {
		message_buffer[i-2] = '\0';
		i--;
	}
	return message_buffer;
}

static const char *Success(const char *result) /* {{{1 */
{
	/* printf("OK\n"); */
	return result;
}

static const char *Failure(const char *result) /* {{{1 */
{
	/* if (result && strlen(result)) MessageBox(result); */
	return result;
}

static const char *execute(char *command, int wait) /* {{{1 */
{
	STARTUPINFO si;
	PROCESS_INFORMATION pi;
	ZeroMemory(&si, sizeof(si));
	ZeroMemory(&pi, sizeof(pi));
	si.cb = sizeof(si);
	if (CreateProcess(0, command, 0, 0, 0, CREATE_NO_WINDOW, 0, 0, &si, &pi)) {
		if (!wait) {
			return Success(NULL);
		} else {
			DWORD exit_code;
			if (WaitForSingleObject(pi.hProcess, INFINITE) != WAIT_FAILED
				 	&& GetExitCodeProcess(pi.hProcess, &exit_code)
				 	&& CloseHandle(pi.hProcess)
					&& CloseHandle(pi.hThread)
					&& sprintf(rv_buffer, "exit_code=%u", exit_code)) {
				return Success(rv_buffer);
			}
		}
	}
	return Failure(GetError());
}

__declspec(dllexport)
const char *execute_synchronous(char *command) /* {{{1 */
{
	return execute(command, 1);
}

__declspec(dllexport)
const char *execute_asynchronous(char *command) /* {{{1 */
{
	return execute(command, 0);
}

__declspec(dllexport)
const char *libversion(const char *ignored) /* {{{1 */
{
	(void)ignored;
	return Success("0.5");
}

__declspec(dllexport)
const char *openurl(const char *path) /* {{{1 */
{
	ShellExecute(NULL, "open", path, NULL, NULL, SW_SHOWNORMAL);
	return Success(NULL);
}

__declspec(dllexport)
const char *fullscreen(const char *options) /* {{{1 */
{
	HWND window;
	LONG styles, exStyle, enable, always_on_top;
	HMONITOR monitor;
	MONITORINFO info = { sizeof info };

	enable = (strstr(options, "enable") != NULL);
	always_on_top = (strstr(options, "always on top") != NULL);

	window = GetForegroundWindow();
	if (!window)
		return Failure("Could not get handle to foreground window!");

	styles = GetWindowLong(window, GWL_STYLE);
	if (!styles)
		return Failure("Could not query window styles!");

	exStyle = GetWindowLong(window, GWL_EXSTYLE);
	if (!exStyle)
		return Failure("Could not query window ex style!");

	if (enable) { 
		styles ^= WS_CAPTION | WS_THICKFRAME;
		if (always_on_top)
			exStyle |= WS_EX_TOPMOST;
	} else {
		styles |= WS_CAPTION | WS_THICKFRAME;
		if (always_on_top)
			exStyle &= ~WS_EX_TOPMOST;
	}

	if (!SetWindowLong(window, GWL_STYLE, styles))
		return Failure("Could not apply window styles!");

	if (!SetWindowLong(window, GWL_EXSTYLE, exStyle))
		return Failure("Could not apply window ex style!");

	if (enable) {
		monitor = MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST);
		if (!monitor)
			return Failure("Could not get handle to monitor!");
		if (!GetMonitorInfo(monitor, &info))
			return Failure("Could not get monitor information!");
		if (!SetWindowPos(window,
					always_on_top ? HWND_TOPMOST : HWND_TOP,
					info.rcMonitor.left,
					info.rcMonitor.top,
					info.rcMonitor.right - info.rcMonitor.left,
					info.rcMonitor.bottom - info.rcMonitor.top,
					SWP_SHOWWINDOW))
			return Failure("Could not resize window!");
	} else if (!SetWindowPos(window, HWND_NOTOPMOST, 0, 0, 0, 0,
				SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED))
		return Failure("Could not restore window!");

	return Success(NULL);
}

__declspec(dllexport)
const char *console(char *command) /* {{{1 */
{
	/* TODO: The quest to embedding a command prompt in Vim :)
	 * This doesn't quite work and I'm afraid it never will.
	 */
	HWND gvim, console;

	gvim = GetForegroundWindow();
	if (!gvim)
		return Failure("Could not get handle to foreground window");

	// destroy old console?
	if (GetConsoleWindow()) FreeConsole();

	// allocate new console
	if (!AllocConsole())
		return Failure("Could not allocate console");

	// get handle to console window
	console = GetConsoleWindow();
	if (!console)
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
