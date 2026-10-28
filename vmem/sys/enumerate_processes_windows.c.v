module sys

// enumerate_processes pushes every visible OS process into sink.
pub fn enumerate_processes(mut sink ProcessSink) ! {
	snap := C.CreateToolhelp32Snapshot(win_th32cs_snap_process, 0)
	if snap == unsafe { nil } {
		return error_with_code('CreateToolhelp32Snapshot(process)', int(C.GetLastError()))
	}
	defer {
		C.CloseHandle(snap)
	}
	mut e := ProcessEntry32W{}
	e.dw_size = u32(sizeof(ProcessEntry32W))
	if C.vmem_Process32FirstW(snap, voidptr(&e)) == 0 {
		return error_with_code('Process32FirstW', int(C.GetLastError()))
	}
	for {
		name := unsafe { string_from_wide(&e.sz_exe_file[0]) }
		sink.push(int(e.th32_process_id), name, name)
		if C.vmem_Process32NextW(snap, voidptr(&e)) == 0 {
			break
		}
	}
}
