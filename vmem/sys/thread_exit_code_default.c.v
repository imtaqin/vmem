module sys

// thread_exit_code is an unsupported-platform fallback.
pub fn thread_exit_code(th voidptr) !u64 {
	return error('thread_exit_code unsupported on this OS')
}
