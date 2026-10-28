module vmem

// kill marks the fake target as killed.
pub fn (mut b FakeBackend) kill() ! {
	b.killed = true
}
