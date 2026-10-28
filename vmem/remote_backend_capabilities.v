module vmem

// capabilities advertises RemoteBackend features: agent-side scan offload
// is available (same ScanPlan semantics, executed on the device).
pub fn (r &RemoteBackend) capabilities() Capabilities {
	return Capabilities{
		scan_offload: true
		regs:         false
		alloc:        false
		inject:       false
	}
}
