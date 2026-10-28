module sys

// suspend_process is an unsupported-platform fallback.
pub fn suspend_process(h voidptr) ! {
	return error('suspend_process unsupported on this OS')
}
