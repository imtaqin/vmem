module vmem

// detach marks the fake backend as not attached.
pub fn (mut b FakeBackend) detach() ! {
	b.attached = false
}
