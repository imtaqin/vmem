module vmem

// Internal pointer-scan recursion (one concern; AGENTS.md §3).
// Finds slots whose qword value points at tgt within +-max_off, emits one
// path per hit (base = slot, offsets deepest-first), and recurses toward
// static anchors up to max_depth.

fn collect_pointers(mut backend MemoryBackend, tgt u64, max_off u64, max_depth int, depth int, mut chain []i64, mut paths []PointerPath, limit int, filter ScanFilter) {
	if paths.len >= limit {
		return
	}
	lo := if tgt > max_off { tgt - max_off } else { u64(0) }
	hi := tgt + max_off
	mut s := new_scan_session()
	plan := ScanPlan{
		kind:   .qword
		op:     .between
		value:  f64(lo)
		value2: f64(hi)
		limit:  limit
		filter: filter
	}
	scan_first(mut backend, mut s, plan) or { return }
	hits := get_results(&s, 0, 0)
	for e in hits {
		if paths.len >= limit {
			return
		}
		v := decode_u64_le(e.raw)
		off := i64(tgt) - i64(v)
		mut nchain := [off]
		nchain << chain
		paths << PointerPath{
			base:    e.address
			offsets: nchain.clone()
		}
		if depth + 1 < max_depth {
			collect_pointers(mut backend, e.address, max_off, max_depth, depth + 1, mut nchain, mut
				paths, limit, filter)
		}
	}
}
