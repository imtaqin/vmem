module sys

// debug_wait_event waits for the next debug event; a zero code means the
// wait timed out.
pub fn debug_wait_event(timeout_ms int) !DebugEvent {
	mut ev := DebugEventRaw{}
	tmo := if timeout_ms < 0 { u32(0xFFFFFFFF) } else { u32(timeout_ms) }
	if C.vmem_WaitForDebugEvent(voidptr(&ev), tmo) == 0 {
		os_code := int(C.GetLastError())
		if os_code == 121 {
			// ERROR_SEM_TIMEOUT
			return DebugEvent{}
		}
		return error_with_code('WaitForDebugEvent', os_code)
	}
	return DebugEvent{
		code: ev.code
		pid:  int(ev.pid)
		tid:  int(ev.tid)
	}
}
