module sys

// debug_detach stops debugging pid.
pub fn debug_detach(pid int) ! {
	if C.vmem_DebugActiveProcessStop(u32(pid)) == 0 {
		return error_with_code('DebugActiveProcessStop pid=${pid}', int(C.GetLastError()))
	}
}
