module vmem

fn test_match_int_value_ops() {
	assert match_int(.eq, 75, 0, 0, 75, 0, 0)
	assert !match_int(.eq, 75, 0, 0, 76, 0, 0)
	assert match_int(.ne, 75, 0, 0, 76, 0, 0)
	assert match_int(.gt, 100, 0, 0, 75, 0, 0)
	assert !match_int(.gt, 75, 0, 0, 75, 0, 0)
	assert match_int(.ge, 75, 0, 0, 75, 0, 0)
	assert match_int(.lt, 50, 0, 0, 75, 0, 0)
	assert match_int(.le, 75, 0, 0, 75, 0, 0)
	assert match_int(.between, 75, 0, 0, 50, 100, 0)
	assert !match_int(.between, 49, 0, 0, 50, 100, 0)
}

fn test_match_int_delta_ops() {
	assert match_int(.changed, 10, 5, 5, 0, 0, 0)
	assert !match_int(.changed, 5, 5, 5, 0, 0, 0)
	assert match_int(.unchanged, 5, 5, 5, 0, 0, 0)
	assert match_int(.increased, 6, 5, 5, 0, 0, 0)
	assert match_int(.decreased, 4, 5, 5, 0, 0, 0)
	assert match_int(.increased_by, 9, 5, 5, 4, 0, 0)
	assert match_int(.decreased_by, 2, 5, 5, 3, 0, 0)
	assert match_int(.same_as_first, 5, 9, 5, 0, 0, 0)
	assert match_int(.unknown, 123, 0, 0, 0, 0, 0)
}

fn test_match_int_fuzzy_delta() {
	// fuzzy ops treat value as the delta
	assert match_int(.fuzzy_eq, 105, 100, 100, 5, 0, 5)
	assert !match_int(.fuzzy_eq, 106, 100, 100, 5, 0, 5)
	assert match_int(.fuzzy_ne, 106, 100, 100, 5, 0, 5)
	assert match_int(.fuzzy_gt, 106, 100, 100, 5, 0, 5)
	assert !match_int(.fuzzy_gt, 104, 100, 100, 5, 0, 5)
	assert match_int(.fuzzy_lt, 94, 100, 100, 5, 0, 5)
}

fn test_match_float_ops() {
	assert match_float(.eq, 1.5, 0, 0, 1.5, 0, 0)
	assert match_float(.between, 2.25, 0, 0, 1.0, 3.0, 0)
	assert match_float(.increased, 2.0, 1.5, 1.5, 0, 0, 0)
	assert match_float(.decreased_by, 0.5, 1.5, 1.5, 1.0, 0, 0)
	assert match_float(.fuzzy_eq, 1.02, 1.0, 1.0, 0.5, 0, 0.5)
}

fn test_match_kind_dispatch() {
	z := [u8(0), 0, 0, 0]
	c := [u8(75), 0, 0, 0]
	plan := ScanPlan{
		kind:  .dword
		op:    .eq
		value: 75
	}
	assert match_kind(.dword, .eq, c, z, z, plan)
	fplan := ScanPlan{
		kind:  .float
		op:    .gt
		value: 1.0
	}
	mut fb := []u8{len: 4}
	encode_f32_le(f32(1.5), mut fb)
	assert match_kind(.float, .gt, fb, fb, fb, fplan)
}

fn test_match_kind_xor_key() {
	// stored value = 75 ^ 0x0F = 68; scan for 75 with xor_key 0x0F
	stored := [u8(68), 0, 0, 0]
	plan := ScanPlan{
		kind:    .dword
		op:      .eq
		value:   75
		xor_key: 0x0F
	}
	assert match_kind(.dword, .eq, stored, stored, stored, plan)
}

fn test_match_kind_address_mask() {
	// pointer scan: value matches 0x12345000 with mask 0xFFFFF000
	cur := [u8(0x34), 0x50, 0x34, 0x12]
	plan := ScanPlan{
		kind:  .dword
		op:    .eq
		value: f64(0x12345FFF)
		mask:  0xFFFFF000
	}
	assert match_kind(.dword, .eq, cur, cur, cur, plan)
	plan2 := ScanPlan{
		kind:  .dword
		op:    .eq
		value: f64(0x12346000)
		mask:  0xFFFFF000
	}
	assert !match_kind(.dword, .eq, cur, cur, cur, plan2)
}

fn test_match_pattern() {
	pat := parse_aob('48 8B ?? C3') or { panic(err) }
	assert match_pattern([u8(0x48), 0x8B, 0x2A, 0xC3], pat)
	assert match_pattern([u8(0x48), 0x8B, 0x00, 0xC3], pat)
	assert !match_pattern([u8(0x48), 0x8B, 0x2A, 0xC2], pat)
	assert !match_pattern([u8(0x48), 0x8B], pat)
	// nibble wildcards
	pat2 := parse_aob('A? ?F') or { panic(err) }
	assert match_pattern([u8(0xA3), 0x7F], pat2)
	assert !match_pattern([u8(0xB3), 0x7F], pat2)
}
