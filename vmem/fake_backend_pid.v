module vmem

// pid returns the target pid the fake backend is attached to.
pub fn (b &FakeBackend) pid() int {
	return b.target_pid
}
