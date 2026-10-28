module vmem

// resume clears the fake suspended flag.
pub fn (mut b FakeBackend) resume() ! {
	b.suspended = false
}
