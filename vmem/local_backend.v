module vmem

// LocalBackend targets a process on the same machine via vmem/sys.
// Thread-safety: one backend per thread; no internal locking (AGENTS.md §4).
pub struct LocalBackend {
mut:
	target_pid int
	handle     voidptr
	attached   bool
}
