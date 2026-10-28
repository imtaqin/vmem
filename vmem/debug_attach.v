module vmem

import vmem.sys

// debug_attach starts an external debug session on the backend's target.
// The target survives detach (kill-on-exit disabled).
pub fn debug_attach(mut b LocalBackend) !DebugSession {
	if !b.attached {
		return new_error(.not_attached, 'debug_attach', 0)
	}
	sys.debug_attach(b.target_pid) or {
		return wrap_err(.access_denied, 'debug_attach pid=${b.target_pid}', err)
	}
	// drain attach events (incl. the system breakpoint) so wait_hit only
	// sees real hits (bounded: the debugger pauses the target per event)
	mut drain := 0
	for drain < 4096 {
		drain++
		evt := sys.debug_wait_event(50) or { break }
		if evt.code == 0 {
			break
		}
		sys.debug_continue(evt.pid, evt.tid) or { break }
	}
	return DebugSession{
		pid:      b.target_pid
		handle:   b.handle
		attached: true
	}
}
