module sys

// alloc_memory is an unsupported-platform fallback.
pub fn alloc_memory(h voidptr, size u64, prot u32) !u64 {
	return error('alloc_memory unsupported on this OS')
}
