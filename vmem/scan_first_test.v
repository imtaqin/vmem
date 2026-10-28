module vmem

// Fake-backend scan tests: deterministic memory, known layout.

fn fake_mem() []u8 {
	mut mem := []u8{len: 512}
	// dword 75 at 0x10 and 0x40 (little-endian), 100 at 0x80
	encode_u32_le(u32(75), mut mem[0x10..0x14])
	encode_u32_le(u32(75), mut mem[0x40..0x44])
	encode_u32_le(u32(100), mut mem[0x80..0x84])
	// dword 75 at odd address 0x51 (missed by align=4)
	encode_u32_le(u32(75), mut mem[0x51..0x55])
	return mem
}

fn test_scan_first_eq() {
	mut b := new_fake_backend(100, 0x10000, fake_mem())
	mut s := new_scan_session()
	plan := ScanPlan{
		kind:  .dword
		op:    .eq
		value: 75
	}
	n := scan_first(mut b, mut s, plan) or { panic(err) }
	assert n == 3
	assert s.addresses == [u64(0x10010), 0x10040, 0x10051]
}

fn test_scan_first_alignment() {
	mut b := new_fake_backend(100, 0x10000, fake_mem())
	mut s := new_scan_session()
	plan := ScanPlan{
		kind:  .dword
		op:    .eq
		value: 75
		align: 4
	}
	n := scan_first(mut b, mut s, plan) or { panic(err) }
	assert n == 2
	assert s.addresses == [u64(0x10010), 0x10040]
}

fn test_scan_first_limit_and_unknown() {
	mut b := new_fake_backend(100, 0x10000, fake_mem())
	mut s := new_scan_session()
	plan := ScanPlan{
		kind:  .byte
		op:    .unknown
		limit: 10
	}
	n := scan_first(mut b, mut s, plan) or { panic(err) }
	assert n == 10
	assert result_count(&s) == 10
}

fn test_scan_first_range_filter() {
	mut b := new_fake_backend(100, 0x10000, fake_mem())
	mut s := new_scan_session()
	plan := ScanPlan{
		kind:   .dword
		op:     .eq
		value:  75
		filter: ScanFilter{
			start: 0x10040
		}
	}
	n := scan_first(mut b, mut s, plan) or { panic(err) }
	assert n == 2
	assert s.addresses == [u64(0x10040), 0x10051]
}

fn test_scan_next_delta_ops() {
	mut b := new_fake_backend(100, 0x10000, fake_mem())
	mut s := new_scan_session()
	first := ScanPlan{
		kind:  .dword
		op:    .eq
		value: 75
	}
	assert (scan_first(mut b, mut s, first) or { panic(err) }) == 3
	// mutate: 0x10 -> 80 (increased), 0x40 -> 70 (decreased), 0x51 keeps 75
	mut buf := []u8{len: 4}
	encode_u32_le(u32(80), mut buf)
	b.write_bytes(0x10010, buf) or { panic(err) }
	encode_u32_le(u32(70), mut buf)
	b.write_bytes(0x10040, buf) or { panic(err) }
	// increased keeps only 0x10
	inc := ScanPlan{
		kind: .dword
		op:   .increased
	}
	assert (scan_next(mut b, mut s, inc) or { panic(err) }) == 1
	assert s.addresses == [u64(0x10010)]
	// eq 75 re-scan: now only 0x51
	assert (scan_first(mut b, mut s, first) or { panic(err) }) == 1
	// unknown scan (stride 4) captures current state (0x10=80, 0x40=70, 0x51=75)
	unknown := ScanPlan{
		kind:  .dword
		op:    .unknown
		align: 4
	}
	assert (scan_first(mut b, mut s, unknown) or { panic(err) }) == 128
	// decrease 0x10 to 30 -> decreased keeps only 0x10
	encode_u32_le(u32(30), mut buf)
	b.write_bytes(0x10010, buf) or { panic(err) }
	dec := ScanPlan{
		kind: .dword
		op:   .decreased
	}
	assert (scan_next(mut b, mut s, dec) or { panic(err) }) == 1
	assert s.addresses == [u64(0x10010)]
	// no change since the last scan -> unchanged keeps the hit
	same := ScanPlan{
		kind: .dword
		op:   .unchanged
	}
	assert (scan_next(mut b, mut s, same) or { panic(err) }) == 1
	// changed drops it
	chg := ScanPlan{
		kind: .dword
		op:   .changed
	}
	assert (scan_next(mut b, mut s, chg) or { panic(err) }) == 0
}

fn test_scan_refine_keeps_prev_state() {
	mut b := new_fake_backend(100, 0x10000, fake_mem())
	mut s := new_scan_session()
	first := ScanPlan{
		kind:  .dword
		op:    .eq
		value: 75
	}
	assert (scan_first(mut b, mut s, first) or { panic(err) }) == 3
	refine := ScanPlan{
		kind:  .dword
		op:    .lt
		value: 76
	}
	assert (scan_refine(mut b, mut s, refine) or { panic(err) }) == 3
	refine2 := ScanPlan{
		kind:  .dword
		op:    .gt
		value: 75
	}
	assert (scan_refine(mut b, mut s, refine2) or { panic(err) }) == 0
}

fn test_edit_all_and_results() {
	mut b := new_fake_backend(100, 0x10000, fake_mem())
	mut s := new_scan_session()
	first := ScanPlan{
		kind:  .dword
		op:    .eq
		value: 75
	}
	assert (scan_first(mut b, mut s, first) or { panic(err) }) == 3
	written := edit_all(mut b, &s, 9) or { panic(err) }
	assert written == 3
	assert read_u32_test_helper(mut b, 0x10010) == u32(9)
	res := get_results(&s, 0, 0)
	assert res.len == 3
	assert res[0].address == u64(0x10010)
	assert res[0].stable == 1
}

fn read_u32_test_helper(mut b FakeBackend, addr u64) u32 {
	mut buf := []u8{len: 4}
	b.read_bytes(addr, mut buf) or { panic(err) }
	return decode_u32_le(buf)
}
