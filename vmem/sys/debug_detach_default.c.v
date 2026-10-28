module sys

// debug_detach is an unsupported-platform fallback.
pub fn debug_detach(pid int) ! {
	return error('debug_detach unsupported on this OS')
}
