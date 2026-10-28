module vmem

// MemoryBackend is the engine seam (ARCHITECTURE.md §3): every target is
// addressed through it — local OS, remote device agent, or fake for tests.
// Methods use `mut` receivers; implementations must document thread-safety.
pub interface MemoryBackend {
	pid() int
	capabilities() Capabilities
	attach(pid int) !
	detach() !
	read_bytes(addr u64, mut buf []u8) !int
	write_bytes(addr u64, buf []u8) !int
	enumerate_regions() ![]Region
	enumerate_modules() ![]ModuleInfo
	suspend() !
	resume() !
	kill() !
	alloc_memory(size u64, prot u32) !u64
	free_memory(addr u64) !
	protect_memory(addr u64, size u64, prot u32) !u32
}
