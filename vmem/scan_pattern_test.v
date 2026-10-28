module vmem

import os

// Pattern scan tests over the fake backend (AGENTS.md §5).

fn pattern_mem() []u8 {
	mut mem := []u8{len: 256}
	// aob 48 8B 2A C3 at 0x20
	mem[0x20] = 0x48
	mem[0x21] = 0x8B
	mem[0x22] = 0x2A
	mem[0x23] = 0xC3
	// text 'vmem-x' at 0x40
	tb := 'vmem-x'.bytes()
	for i in 0 .. tb.len {
		mem[0x40 + i] = tb[i]
	}
	// group 75, *, 100 (dwords) at 0x80
	encode_u32_le(u32(75), mut mem[0x80..0x84])
	mem[0x85] = 0xEE // middle dword garbage
	encode_u32_le(u32(100), mut mem[0x88..0x8C])
	// range group 6, 7 at 0xA0
	encode_u32_le(u32(6), mut mem[0xA0..0xA4])
	encode_u32_le(u32(7), mut mem[0xA4..0xA8])
	// xor-encoded value 75 ^ 0x0F = 68 at 0xC0
	encode_u32_le(u32(68), mut mem[0xC0..0xC4])
	return mem
}

fn test_scan_aob() {
	mut b := new_fake_backend(7, 0x2000, pattern_mem())
	mut s := new_scan_session()
	pat := parse_aob('48 8B ?? C3') or { panic(err) }
	plan := ScanPlan{
		kind:    .aob
		op:      .eq
		pattern: pat
	}
	n := scan_first(mut b, mut s, plan) or { panic(err) }
	assert n == 1
	assert s.addresses == [u64(0x2020)]
	assert result_count(&s) == 1
	// edit_all on aob writes the pattern bytes (wildcard position overwritten)
	edited := edit_all(mut b, &s, 0) or { panic(err) }
	assert edited == 1
	mut buf := []u8{len: 4}
	b.read_bytes(0x2020, mut buf) or { panic(err) }
	assert buf == [u8(0x48), 0x8B, 0x00, 0xC3]
}

fn test_scan_text() {
	mut b := new_fake_backend(7, 0x2000, pattern_mem())
	mut s := new_scan_session()
	pat := pattern_from_text('vmem-x', .utf8) or { panic(err) }
	plan := ScanPlan{
		kind:    .text
		op:      .eq
		pattern: pat
	}
	n := scan_first(mut b, mut s, plan) or { panic(err) }
	assert n == 1
	assert s.addresses == [u64(0x2040)]
}

fn test_scan_group_ce() {
	mut b := new_fake_backend(7, 0x2000, pattern_mem())
	mut s := new_scan_session()
	pat := parse_group_ce('4:75 4:* 4:100') or { panic(err) }
	plan := ScanPlan{
		kind:    .aob
		op:      .eq
		pattern: pat
	}
	n := scan_first(mut b, mut s, plan) or { panic(err) }
	assert n == 1
	assert s.addresses == [u64(0x2080)]
}

fn test_scan_group_gg_range() {
	mut b := new_fake_backend(7, 0x2000, pattern_mem())
	mut s := new_scan_session()
	pat := parse_group_gg('6~7;7', .dword) or { panic(err) }
	plan := ScanPlan{
		kind:    .aob
		op:      .eq
		pattern: pat
	}
	n := scan_first(mut b, mut s, plan) or { panic(err) }
	assert n == 1
	assert s.addresses == [u64(0x20A0)]
}

fn test_scan_xor_key() {
	mut b := new_fake_backend(7, 0x2000, pattern_mem())
	mut s := new_scan_session()
	plan := ScanPlan{
		kind:    .dword
		op:      .eq
		value:   75
		xor_key: 0x0F
	}
	n := scan_first(mut b, mut s, plan) or { panic(err) }
	assert n == 1
	assert s.addresses == [u64(0x20C0)]
}

fn test_scan_aob_delta_ops() {
	mut b := new_fake_backend(7, 0x2000, pattern_mem())
	mut s := new_scan_session()
	pat := parse_aob('48 8B ?? C3') or { panic(err) }
	plan := ScanPlan{
		kind:    .aob
		op:      .eq
		pattern: pat
	}
	assert (scan_first(mut b, mut s, plan) or { panic(err) }) == 1
	// mutate the wildcard byte -> changed keeps it
	mut w := []u8{len: 1}
	w[0] = 0x99
	b.write_bytes(0x2022, w) or { panic(err) }
	chg := ScanPlan{
		kind: .aob
		op:   .changed
	}
	assert (scan_next(mut b, mut s, chg) or { panic(err) }) == 1
	// frozen -> changed drops it
	assert (scan_next(mut b, mut s, chg) or { panic(err) }) == 0
}

fn test_dump_memory_and_hex() {
	mut b := new_fake_backend(7, 0x2000, pattern_mem())
	mbin := os.join_path(os.temp_dir(), 'vmem_dump.bin')
	hpath := os.join_path(os.temp_dir(), 'vmem_dump.txt')
	n := dump_memory(mut b, mbin, 0x2020, 0x2024) or { panic(err) }
	assert n == 4
	data := os.read_file(mbin) or { panic(err) }
	assert data.bytes() == [u8(0x48), 0x8B, 0x2A, 0xC3]
	nh := dump_hex(mut b, hpath, 0x2020, 0x2028, 4) or { panic(err) }
	assert nh == 8
	txt := os.read_file(hpath) or { panic(err) }
	assert txt.contains('48 8b 2a c3')
	os.rm(mbin) or {}
	os.rm(hpath) or {}
}
