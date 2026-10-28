module sys

// debug_continue resumes the debuggee after an event.
pub fn debug_continue(pid int, tid int) ! {
	if C.vmem_ContinueDebugEvent(u32(pid), u32(tid), win_dbg_continue) == 0 {
		return error_with_code('ContinueDebugEvent pid=${pid}', int(C.GetLastError()))
	}
}
