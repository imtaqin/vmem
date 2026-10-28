module vmem

// attach retargets the fake backend to pid (re-attach is allowed).
pub fn (mut b FakeBackend) attach(pid int) ! {
	b.target_pid = pid
	b.attached = true
}
