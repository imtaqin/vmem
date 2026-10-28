module sys

// debug_wait_event is an unsupported-platform fallback.
pub fn debug_wait_event(timeout_ms int) !DebugEvent {
	return error('debug_wait_event unsupported on this OS')
}
