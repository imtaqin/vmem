module vmem

// new_fake_backend returns an attached FakeBackend over a private copy of mem,
// mapped at base for pid.
pub fn new_fake_backend(pid int, base u64, mem []u8) FakeBackend {
	return FakeBackend{
		target_pid: pid
		base:       base
		mem:        mem.clone()
		attached:   true
	}
}
