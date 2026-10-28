module vmem

// Pointer scan tests over a small fake graph:
//   0x1080 -> 0x1040 -> 0x1090 (target, holds marker)
//   0x1060 -> 0x1088 (target - 8, offset path)

fn pointer_mem() []u8 {
	mut mem := []u8{len: 256}
	encode_u64_le(u64(0x1090), mut mem[0x40..0x48]) // direct pointer to target
	encode_u64_le(u64(0x1040), mut mem[0x80..0x88]) // pointer to the slot
	encode_u64_le(u64(0x1088), mut mem[0x60..0x68]) // target - 8 (offset path)
	encode_u32_le(u32(0x71717171), mut mem[0x90..0x94])
	return mem
}

fn test_pointer_scan_and_resolve() {
	mut b := new_fake_backend(1, 0x1000, pointer_mem())
	paths := pointer_scan(mut b, 0x1090, 0, 2, 16, ScanFilter{}) or { panic(err) }
	// depth-1: 0x1040 -> target; depth-2: 0x1080 -> 0x1040 -> target
	assert paths.len == 2
	mut bases := []u64{}
	for p in paths {
		bases << p.base
		v := resolve_pointer(mut b, p) or { panic(err) }
		assert v == u64(0x1090)
	}
	assert u64(0x1040) in bases
	assert u64(0x1080) in bases
}

fn test_pointer_scan_with_offset() {
	mut b := new_fake_backend(1, 0x1000, pointer_mem())
	paths := pointer_scan(mut b, 0x1090, 8, 1, 16, ScanFilter{}) or { panic(err) }
	// 0x1060 holds 0x1088 -> offset 8; 0x1040 holds 0x1090 -> offset 0
	assert paths.len == 2
	mut offs := []i64{}
	for p in paths {
		offs << p.offsets[0]
		v := resolve_pointer(mut b, p) or { panic(err) }
		assert v == u64(0x1090)
	}
	assert i64(8) in offs
	assert i64(0) in offs
}

fn test_rescan_pointers_filters_stale() {
	mut b := new_fake_backend(1, 0x1000, pointer_mem())
	paths := pointer_scan(mut b, 0x1090, 0, 2, 16, ScanFilter{}) or { panic(err) }
	assert paths.len == 2
	// relocate: the direct slot now points somewhere else
	mut buf := []u8{len: 8}
	encode_u64_le(u64(0x10DEAD), mut buf)
	b.write_bytes(0x1040, buf) or { panic(err) }
	kept := rescan_pointers(mut b, paths, 0x1090) or { panic(err) }
	assert kept.len == 0
}
