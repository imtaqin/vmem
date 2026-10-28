module vmem

// plan_width returns the byte width a plan scans for: the scalar kind size
// or the pattern length for aob/text scans.
pub fn plan_width(p ScanPlan) int {
	match p.kind {
		.aob, .text { return p.pattern.bytes.len }
		else { return kind_size(p.kind) }
	}
}
