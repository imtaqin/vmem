module vmem

fn test_scan_first_parallel_self() {
	mut marker := u32(0x0BADF00D)
	addr := u64(unsafe { usize(&marker) })
	plan := ScanPlan{
		kind:  .dword
		op:    .eq
		value: f64(0x0BADF00D)
	}
	mut s := new_scan_session()
	n := scan_first_parallel(current_pid(), mut s, plan) or { panic(err) }
	assert n >= 1
	assert addr in s.addresses
	assert marker == u32(0x0BADF00D) // keep marker alive
}
