module vmem

import runtime

// scan_first_parallel is scan_first over a local pid using up to
// runtime.nr_cpus() worker threads (one backend handle each). The merged
// result is deterministic: region slices are contiguous and merged in
// worker order, matching scan_first's ascending output.
//
// Intended for local targets; remote backends should scan agent-side
// (Capabilities.scan_offload). Plan.limit applies to the merged result.
pub fn scan_first_parallel(pid int, mut s ScanSession, plan ScanPlan) !int {
	sz := kind_size(plan.kind)
	if sz == 0 {
		return new_error(.unsupported, 'scan kind ${plan.kind} (v1 scalar kinds only)', 0)
	}
	mut probe := new_local_backend(pid)!
	regions := probe.enumerate_regions()!
	probe.detach() or {}

	s.kind = plan.kind
	s.op = plan.op
	s.align = if plan.align == 0 { u64(1) } else { plan.align }
	s.addresses = []
	s.prev_raw = []
	s.first_raw = []
	s.stable = []
	s.total_hits = 0
	s.scans = 1

	mut scoped := []Region{}
	for r in regions {
		if region_in_scope(r, plan.filter) {
			scoped << r
		}
	}
	mut workers := runtime.nr_cpus()
	if workers > 16 {
		workers = 16
	}
	if workers > scoped.len {
		workers = scoped.len
	}
	if workers <= 1 {
		mut b := new_local_backend(pid)!
		defer {
			b.detach() or {}
		}
		scan_collect(mut b, scoped, plan, sz, s.align, mut s.addresses, mut s.prev_raw, mut
			s.first_raw, mut s.stable, plan.limit)
		s.total_hits = s.addresses.len
		return s.addresses.len
	}

	// contiguous region slices -> merge in worker order keeps ascending order
	per := (scoped.len + workers - 1) / workers
	mut handles := []thread WorkerHits{}
	for start := 0; start < scoped.len; start += per {
		mut stop := start + per
		if stop > scoped.len {
			stop = scoped.len
		}
		slice := scoped[start..stop].clone()
		handles << spawn scan_regions_worker(pid, slice, plan, sz, s.align)
	}
	for h in handles {
		wh := h.wait()
		s.addresses << wh.addresses
		s.prev_raw << wh.prev_raw
		s.first_raw << wh.first_raw
		s.stable << wh.stable
	}
	if plan.limit > 0 && s.addresses.len > plan.limit {
		s.addresses = s.addresses[..plan.limit]
		s.prev_raw = s.prev_raw[..plan.limit * sz]
		s.first_raw = s.first_raw[..plan.limit * sz]
		s.stable = s.stable[..plan.limit]
	}
	s.total_hits = s.addresses.len
	return s.addresses.len
}
