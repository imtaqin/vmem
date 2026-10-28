module sys

// enumerate_modules pushes every loaded image (exe/dll) of the target.
pub fn enumerate_modules(h voidptr, mut sink ModuleSink) ! {
	pid := pid_of_handle(h)
	snap := C.CreateToolhelp32Snapshot(win_th32cs_snap_module | win_th32cs_snap_module32, u32(pid))
	if snap == unsafe { nil } {
		return error_with_code('CreateToolhelp32Snapshot(module) pid=${pid}', int(C.GetLastError()))
	}
	defer {
		C.CloseHandle(snap)
	}
	mut e := ModuleEntry32W{}
	e.dw_size = u32(sizeof(ModuleEntry32W))
	if C.vmem_Module32FirstW(snap, voidptr(&e)) == 0 {
		return error_with_code('Module32FirstW pid=${pid}', int(C.GetLastError()))
	}
	for {
		path := unsafe { string_from_wide(&e.sz_exe_path[0]) }
		sink.push(u64(usize(e.mod_base_addr)), u64(e.mod_base_size), path)
		if C.vmem_Module32NextW(snap, voidptr(&e)) == 0 {
			break
		}
	}
}

// pid_of_handle recovers the pid from a handle (win32_dyn.h resolved).
fn pid_of_handle(h voidptr) int {
	return int(C.vmem_GetProcessId(h))
}
