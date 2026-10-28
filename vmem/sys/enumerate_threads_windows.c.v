module sys

// enumerate_threads returns the thread ids of the target process.
pub fn enumerate_threads(h voidptr) ![]int {
	pid := int(C.vmem_GetProcessId(h))
	snap := C.CreateToolhelp32Snapshot(win_th32cs_snap_thread, 0)
	if snap == unsafe { nil } {
		return error_with_code('CreateToolhelp32Snapshot(thread)', int(C.GetLastError()))
	}
	defer {
		C.CloseHandle(snap)
	}
	mut out := []int{}
	mut e := ThreadEntry32{}
	e.dw_size = u32(sizeof(ThreadEntry32))
	if C.Thread32First(snap, voidptr(&e)) == 0 {
		return error_with_code('Thread32First', int(C.GetLastError()))
	}
	for {
		if int(e.th32_owner_process_id) == pid {
			out << int(e.th32_thread_id)
		}
		if C.Thread32Next(snap, voidptr(&e)) == 0 {
			break
		}
	}
	return out
}
