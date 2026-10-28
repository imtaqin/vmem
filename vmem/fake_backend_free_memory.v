module vmem

// free_memory is a no-op (nothing to free in the fake mapping).
pub fn (mut b FakeBackend) free_memory(addr u64) ! {}
