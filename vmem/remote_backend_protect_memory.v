module vmem

// protect_memory is the agent-side counterpart (P5b work).
pub fn (mut r RemoteBackend) protect_memory(addr u64, size u64, prot u32) !u32 {
	return new_error(.unsupported, 'remote protect_memory (P5b)', 0)
}
