module vmem

// scan_refine filters the current hits by fresh reads against the plan's
// value criteria (eq/ne/gt/ge/lt/le/between). Unlike scan_next it does not
// advance the saved previous bytes and does not bump the scan counter —
// it only drops entries that no longer match (GameGuardian refine model).
pub fn scan_refine(mut backend MemoryBackend, mut s ScanSession, plan ScanPlan) !int {
	if s.scans == 0 {
		return new_error(.state, 'scan_refine before scan_first', 0)
	}
	sz := s.stride
	mut out_addr := []u64{}
	mut out_prev := []u8{}
	mut out_first := []u8{}
	mut out_stable := []u32{}
	mut reader := new_chunk_reader()
	for i in 0 .. s.addresses.len {
		addr := s.addresses[i]
		ok := reader.ensure(mut backend, addr, sz) or { continue }
		if !ok {
			continue
		}
		o := reader.off(addr)
		cur := reader.buf[o..o + sz]
		if match_kind(s.kind, plan.op, cur, cur, cur, plan) {
			out_addr << addr
			out_prev << s.prev_raw[i * sz..(i + 1) * sz]
			out_first << s.first_raw[i * sz..(i + 1) * sz]
			out_stable << s.stable[i]
			if plan.limit > 0 && out_addr.len >= plan.limit {
				break
			}
		}
	}
	s.addresses = out_addr
	s.prev_raw = out_prev
	s.first_raw = out_first
	s.stable = out_stable
	s.total_hits = out_addr.len
	return out_addr.len
}
