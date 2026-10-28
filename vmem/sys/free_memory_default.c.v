module sys

// free_memory is an unsupported-platform fallback.
pub fn free_memory(h voidptr, addr u64) ! {
	return error('free_memory unsupported on this OS')
}
