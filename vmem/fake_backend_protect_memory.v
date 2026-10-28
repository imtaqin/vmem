module vmem

// protect_memory always reports the requested protection for fake pages.
pub fn (mut b FakeBackend) protect_memory(addr u64, size u64, prot u32) !u32 {
	return prot
}
