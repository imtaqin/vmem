module vmem

// scan_next re-reads the current hits and keeps those matching the plan's
// delta/value criteria against the bytes saved at the previous scan
// (plan.value for first scan semantics is the operand; see scan_first doc).
// The session's previous bytes are updated to the freshly read bytes;
// stable counts how many rescans each entry survived.
//
// Memory semantics: same comparison rules as scan_first. Reads use a sliding
// window over the (ascending) hit list, so rescans are chunked, not
// per-hit syscalls.
pub fn scan_next(mut backend MemoryBackend, mut s ScanSession, plan ScanPlan) !int {
	if s.scans == 0 {
		return new_error(.state, 'scan_next before scan_first', 0)
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
		prev := s.prev_raw[i * sz..(i + 1) * sz]
		first := s.first_raw[i * sz..(i + 1) * sz]
		if match_kind(s.kind, plan.op, cur, prev, first, plan) {
			out_addr << addr
			out_prev << cur
			out_first << first
			out_stable << s.stable[i] + 1
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
	s.scans++
	return out_addr.len
}
