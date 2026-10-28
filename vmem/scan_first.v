module vmem

// scan_first scans the target memory for the plan criteria and fills the
// session with the hits (previous bytes saved for later delta scans).
// Returns the number of hits kept (plan.limit may cap it).
//
// Memory semantics: integer kinds compare as sign-extended i64, float kinds
// as f64; equality on float is bitwise-exact. Unknown-initial keeps every
// in-scope address. Reads are chunked through a reusable window buffer; the
// compare loop allocates only when the result arrays grow.
pub fn scan_first(mut backend MemoryBackend, mut s ScanSession, plan ScanPlan) !int {
	sz := plan_width(plan)
	if sz == 0 {
		return new_error(.unsupported, 'scan kind ${plan.kind} (need scalar width or pattern)', 0)
	}
	if plan.kind == .aob || plan.kind == .text {
		match plan.op {
			.eq, .ne, .changed, .unchanged, .unknown {}
			else {
				return new_error(.bad_pattern, 'op ${plan.op} unsupported for pattern scans', 0)
			}
		}
	}
	s.kind = plan.kind
	s.op = plan.op
	s.align = if plan.align == 0 { u64(1) } else { plan.align }
	s.stride = sz
	s.pattern = plan.pattern
	s.addresses = []
	s.prev_raw = []
	s.first_raw = []
	s.stable = []
	s.total_hits = 0
	s.scans = 1

	regions := backend.enumerate_regions()!
	scan_collect(mut backend, regions, plan, sz, s.align, mut s.addresses, mut s.prev_raw, mut
		s.first_raw, mut s.stable, plan.limit)
	s.total_hits = s.addresses.len
	return s.addresses.len
}
