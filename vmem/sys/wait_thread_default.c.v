module sys

// wait_thread is an unsupported-platform fallback.
pub fn wait_thread(th voidptr, ms int) ! {
	return error('wait_thread unsupported on this OS')
}
