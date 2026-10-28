module vmem

// Internal scan scope helpers (one concern; AGENTS.md §3).

// region_in_scope reports whether a region passes the ScanFilter.
fn region_in_scope(r Region, f ScanFilter) bool {
	if f.start != 0 && r.base + r.size <= f.start {
		return false
	}
	if f.end != 0 && r.base >= f.end {
		return false
	}
	if f.classes != 0 && (f.classes & class_bit(r.class)) == 0 {
		return false
	}
	if f.prot_require != 0 && r.prot & f.prot_require != f.prot_require {
		return false
	}
	if f.prot_reject != 0 && r.prot & f.prot_reject != 0 {
		return false
	}
	return true
}

// align_up rounds addr up to the next multiple of a (a==0 behaves as 1).
fn align_up(addr u64, a u64) u64 {
	m := if a <= 1 { u64(1) } else { a }
	rem := addr % m
	if rem == 0 {
		return addr
	}
	return addr + (m - rem)
}
