module sys

// create_thread is an unsupported-platform fallback.
pub fn create_thread(h voidptr, start_addr u64, param u64) !voidptr {
	return error('create_thread unsupported on this OS')
}
