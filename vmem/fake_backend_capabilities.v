module vmem

// capabilities advertises FakeBackend features (all off).
pub fn (b &FakeBackend) capabilities() Capabilities {
	return Capabilities{
		scan_offload: false
		regs:         false
		alloc:        false
		inject:       false
	}
}
