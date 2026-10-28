module vmem

// alloc_memory lands with the P8 agent work
// (PLAN P5b); remote v1 reports the capability as absent.
pub fn (mut r RemoteBackend) alloc_memory(size u64, prot u32) !u64 {
	return new_error(.unsupported, 'remote alloc_memory (P5b)', 0)
}
