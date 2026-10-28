module vmem

// FakeBackend is the deterministic in-memory MemoryBackend for tests.
// Thread-safety: same as LocalBackend (one per thread).
pub struct FakeBackend {
mut:
	target_pid int
	base       u64
	mem        []u8
	attached   bool
	suspended  bool
	killed     bool
}
