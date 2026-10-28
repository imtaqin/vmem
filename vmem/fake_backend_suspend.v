module vmem

// suspend marks the fake target as suspended.
pub fn (mut b FakeBackend) suspend() ! {
	b.suspended = true
}
