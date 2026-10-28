module vmem

// capabilities advertises LocalBackend features.
pub fn (b &LocalBackend) capabilities() Capabilities {
	return Capabilities{
		scan_offload: false
		regs:         false
		alloc:        true
		inject:       true
	}
}
