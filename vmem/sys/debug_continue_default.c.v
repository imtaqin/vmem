module sys

// debug_continue is an unsupported-platform fallback.
pub fn debug_continue(pid int, tid int) ! {
	return error('debug_continue unsupported on this OS')
}
