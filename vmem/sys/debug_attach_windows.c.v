module sys

// debug_attach starts debugging pid (the target keeps running after the
// debugger detaches: kill-on-exit is disabled).
pub fn debug_attach(pid int) ! {
	// order matters: DebugSetProcessKillOnExit needs an active debug object
	if C.vmem_DebugActiveProcess(u32(pid)) == 0 {
		return error_with_code('DebugActiveProcess pid=${pid}', int(C.GetLastError()))
	}
	if C.vmem_DebugSetProcessKillOnExit(0) == 0 {
		return error_with_code('DebugSetProcessKillOnExit', int(C.GetLastError()))
	}
}
