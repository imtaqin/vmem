module sys

// open_process is an unsupported-platform fallback.
pub fn open_process(pid int) !voidptr {
	return error('open_process unsupported on this OS (pid=${pid})')
}
