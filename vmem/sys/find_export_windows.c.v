module sys

// find_export resolves an exported function in a loaded module of the
// CURRENT process (Windows: module bases are shared system-wide, so
// kernel32 exports resolve for remote thread starts too).
pub fn find_export(module_name string, fn_name string) !u64 {
	m := C.GetModuleHandleA(unsafe { &char(module_name.str) })
	if m == unsafe { nil } {
		return error_with_code('GetModuleHandleA ${module_name}', int(C.GetLastError()))
	}
	p := C.GetProcAddress(m, fn_name.str)
	if p == unsafe { nil } {
		return error_with_code('GetProcAddress ${module_name}!${fn_name}', int(C.GetLastError()))
	}
	return u64(usize(p))
}
