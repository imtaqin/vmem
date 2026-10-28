module vmem

// Golden tests for the pattern languages (AGENTS.md §5).

fn test_parse_aob_golden() {
	p := parse_aob('48 8B ?? C3') or { panic(err) }
	assert p.bytes == [u8(0x48), 0x8B, 0x00, 0xC3]
	assert p.mask == [u8(0xFF), 0xFF, 0x00, 0xFF]
	p2 := parse_aob('5c e3 0b') or { panic(err) }
	assert p2.bytes == [u8(0x5C), 0xE3, 0x0B]
	assert p2.mask == [u8(0xFF), 0xFF, 0xFF]
	// nibble wildcards
	p3 := parse_aob('0B?0') or { panic(err) }
	assert p3.bytes == [u8(0x0B), 0x00]
	assert p3.mask == [u8(0xFF), 0x0F]
	// errors
	if x := parse_aob('48 GG') {
		assert false, 'expected bad_pattern, got ${x}'
	}
	if x := parse_aob('') {
		assert false, 'expected bad_pattern, got ${x}'
	}
}

fn test_parse_group_ce_golden() {
	g := parse_group_ce('4:75 4:* 4:100') or { panic(err) }
	assert g.bytes.len == 12
	assert g.mask == [u8(0xFF), 0xFF, 0xFF, 0xFF, 0, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF]
	assert decode_u32_le(g.bytes[0..4]) == u32(75)
	assert decode_u32_le(g.bytes[8..12]) == u32(100)
	// range cell
	g2 := parse_group_ce('4:6~7 4:7') or { panic(err) }
	assert g2.ranges.len == 1
	assert g2.ranges[0].off == 0
	assert g2.ranges[0].lo == 6
	assert g2.ranges[0].hi == 7
	assert g2.ranges[0].width == 4
	// float cell
	g3 := parse_group_ce('f:1.5') or { panic(err) }
	assert g3.bytes.len == 4
	assert decode_f32_le(g3.bytes) == f32(1.5)
}

fn test_parse_group_gg_golden() {
	g := parse_group_gg('6~7;7;1~2;0;0::29', .dword) or { panic(err) }
	assert g.bytes.len == 29
	assert g.ranges.len == 2
	assert g.ranges[0].off == 0
	assert g.ranges[1].off == 8
	// trailing pad is wildcard
	assert g.mask[28] == 0
	// wildcard cell
	g2 := parse_group_gg('*;42', .dword) or { panic(err) }
	assert g2.mask == [u8(0), 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF]
	if x := parse_group_gg('1;2::2', .dword) {
		assert false, 'expected bad_pattern for size < cells, got ${x}'
	}
}

fn test_encode_text() {
	assert encode_text('AB', .utf16le) == [u8(0x41), 0x00, 0x42, 0x00]
	assert encode_text('AB', .utf16be) == [u8(0x00), 0x41, 0x00, 0x42]
	assert encode_text('AB', .utf8) == [u8(0x41), 0x42]
	// surrogate pair (U+1F600)
	e := encode_text('😀', .utf16le)
	assert e.len == 4
	assert e[0] == 0x3D
	assert e[1] == 0xD8
	assert e[2] == 0x00
	assert e[3] == 0xDE
}
