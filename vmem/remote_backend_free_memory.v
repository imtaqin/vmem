module vmem

// free_memory is the agent-side counterpart (P5b work).
pub fn (mut r RemoteBackend) free_memory(addr u64) ! {
	return new_error(.unsupported, 'remote free_memory (P5b)', 0)
}
