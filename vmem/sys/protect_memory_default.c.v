module sys

// protect_memory is an unsupported-platform fallback.
pub fn protect_memory(h voidptr, addr u64, size u64, prot u32) !u32 {
	return error('protect_memory unsupported on this OS')
}
