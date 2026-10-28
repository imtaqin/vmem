module sys

// kill_process is an unsupported-platform fallback.
pub fn kill_process(h voidptr, code int) ! {
	return error('kill_process unsupported on this OS (code=${code})')
}
