module sys

// open_process opens a handle with the read/write/query/suspend rights the
// engine needs. The handle is opaque to callers.
pub fn open_process(pid int) !voidptr {
	access := win_process_vm_read | win_process_vm_write | win_process_vm_operation | win_process_query_information | win_process_suspend_resume | win_process_terminate
	h := C.OpenProcess(access, 0, u32(pid))
	if h == unsafe { nil } {
		return error_with_code('OpenProcess pid=${pid}', int(C.GetLastError()))
	}
	return h
}
