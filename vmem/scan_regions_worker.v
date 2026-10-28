module vmem

// scan_regions_worker scans a disjoint slice of regions using its own
// backend handle (pure function: safe to run in parallel threads).
fn scan_regions_worker(pid int, regions []Region, plan ScanPlan, sz int, align u64) WorkerHits {
	mut wh := WorkerHits{}
	mut b := new_local_backend(pid) or { return wh }
	scan_collect(mut b, regions, plan, sz, align, mut wh.addresses, mut wh.prev_raw, mut
		wh.first_raw, mut wh.stable, 0)
	b.detach() or {}
	return wh
}
