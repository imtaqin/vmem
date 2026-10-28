/* win32_dyn.h — runtime-resolved Win32 imports for Vmem.
 *
 * The bundled tcc's kernel32 import lib lacks GetProcessId and the
 * Module32*W Toolhelp entry points. Resolve them via GetProcAddress so the
 * build never depends on a specific import lib. Signature-compatible with
 * the real prototypes in <tlhelp32.h> / <processthreadsapi.h>.
 */
#ifndef VMEM_WIN32_DYN_H
#define VMEM_WIN32_DYN_H

#include <windows.h>

typedef DWORD(WINAPI *vmem_get_process_id_fn)(HANDLE);
typedef BOOL(WINAPI *vmem_module32_fn)(HANDLE, LPVOID);
typedef BOOL(WINAPI *vmem_process32_fn)(HANDLE, LPVOID);
typedef BOOL(WINAPI *vmem_debug_bool_fn)(DWORD);
typedef BOOL(WINAPI *vmem_debug_event_fn)(LPVOID, DWORD);
typedef BOOL(WINAPI *vmem_debug_cont_fn)(DWORD, DWORD, DWORD);
typedef BOOL(WINAPI *vmem_thread_ctx_fn)(HANDLE, LPVOID);

static voidptr vmem_kernel32_proc(const char *name) {
	static HMODULE k32 = 0;
	if (!k32) {
		k32 = GetModuleHandleA("kernel32.dll");
	}
	return (voidptr)GetProcAddress(k32, name);
}

static DWORD WINAPI vmem_GetProcessId(HANDLE h) {
	static vmem_get_process_id_fn fn = 0;
	if (!fn) {
		fn = (vmem_get_process_id_fn)vmem_kernel32_proc("GetProcessId");
	}
	return fn ? fn(h) : 0;
}

static BOOL WINAPI vmem_Module32FirstW(HANDLE h, LPVOID p) {
	static vmem_module32_fn fn = 0;
	if (!fn) {
		fn = (vmem_module32_fn)vmem_kernel32_proc("Module32FirstW");
	}
	return fn ? fn(h, p) : 0;
}

static BOOL WINAPI vmem_Module32NextW(HANDLE h, LPVOID p) {
	static vmem_module32_fn fn = 0;
	if (!fn) {
		fn = (vmem_module32_fn)vmem_kernel32_proc("Module32NextW");
	}
	return fn ? fn(h, p) : 0;
}

static BOOL WINAPI vmem_Process32FirstW(HANDLE h, LPVOID p) {
	static vmem_process32_fn fn = 0;
	if (!fn) {
		fn = (vmem_process32_fn)vmem_kernel32_proc("Process32FirstW");
	}
	return fn ? fn(h, p) : 0;
}

static BOOL WINAPI vmem_Process32NextW(HANDLE h, LPVOID p) {
	static vmem_process32_fn fn = 0;
	if (!fn) {
		fn = (vmem_process32_fn)vmem_kernel32_proc("Process32NextW");
	}
	return fn ? fn(h, p) : 0;
}

static BOOL WINAPI vmem_DebugActiveProcess(DWORD pid) {
	static vmem_debug_bool_fn fn = 0;
	if (!fn) {
		fn = (vmem_debug_bool_fn)vmem_kernel32_proc("DebugActiveProcess");
	}
	return fn ? fn(pid) : 0;
}

static BOOL WINAPI vmem_DebugActiveProcessStop(DWORD pid) {
	static vmem_debug_bool_fn fn = 0;
	if (!fn) {
		fn = (vmem_debug_bool_fn)vmem_kernel32_proc("DebugActiveProcessStop");
	}
	return fn ? fn(pid) : 0;
}

static BOOL WINAPI vmem_DebugSetProcessKillOnExit(DWORD kill) {
	static vmem_debug_bool_fn fn = 0;
	if (!fn) {
		fn = (vmem_debug_bool_fn)vmem_kernel32_proc("DebugSetProcessKillOnExit");
	}
	return fn ? fn(kill) : 0;
}

static BOOL WINAPI vmem_WaitForDebugEvent(LPVOID ev, DWORD ms) {
	static vmem_debug_event_fn fn = 0;
	if (!fn) {
		fn = (vmem_debug_event_fn)vmem_kernel32_proc("WaitForDebugEvent");
	}
	return fn ? fn(ev, ms) : 0;
}

static BOOL WINAPI vmem_ContinueDebugEvent(DWORD pid, DWORD tid, DWORD status) {
	static vmem_debug_cont_fn fn = 0;
	if (!fn) {
		fn = (vmem_debug_cont_fn)vmem_kernel32_proc("ContinueDebugEvent");
	}
	return fn ? fn(pid, tid, status) : 0;
}

static BOOL WINAPI vmem_GetThreadContext(HANDLE h, LPVOID ctx) {
	static vmem_thread_ctx_fn fn = 0;
	if (!fn) {
		fn = (vmem_thread_ctx_fn)vmem_kernel32_proc("GetThreadContext");
	}
	return fn ? fn(h, ctx) : 0;
}

static BOOL WINAPI vmem_SetThreadContext(HANDLE h, LPVOID ctx) {
	static vmem_thread_ctx_fn fn = 0;
	if (!fn) {
		fn = (vmem_thread_ctx_fn)vmem_kernel32_proc("SetThreadContext");
	}
	return fn ? fn(h, ctx) : 0;
}

#endif /* VMEM_WIN32_DYN_H */
