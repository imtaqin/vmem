module vmem

// alloc_memory reports that the fake has no code pages.
pub fn (mut b FakeBackend) alloc_memory(size u64, prot u32) !u64 {
	return new_error(.unsupported, 'fake alloc_memory', 0)
}
