module vmem

// kind_size returns the scalar width in bytes for a scan/edit value kind.
// Composite kinds (text/aob/encrypted/auto) return 0: their width is set by
// the operand bytes, which v1 scans do not support yet.
pub fn kind_size(k ValueKind) int {
	match k {
		.byte { return 1 }
		.word { return 2 }
		.dword, .float { return 4 }
		.qword, .double { return 8 }
		else { return 0 }
	}
}
