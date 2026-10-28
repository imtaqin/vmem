module vmem

// parse_group_ce parses a Cheat Engine-style grouped layout: cells separated
// by spaces, each `type:value`. Types: 1 2 4 8 (int widths, LE), f (f32),
// d (f64). Values: a number, `*` (any bytes), or `a~b` (value range).
// Example: "4:75 4:* 4:100 2:1~5 f:1.5".
pub fn parse_group_ce(spec string) !ScanPattern {
	mut bytes := []u8{}
	mut mask := []u8{}
	mut ranges := []CellRange{}
	for tok in spec.split(' ') {
		t := tok.trim_space()
		if t == '' {
			continue
		}
		parts := t.split(':')
		if parts.len != 2 {
			return new_error(.bad_pattern, 'group cell "${t}" in "${spec}"', 0)
		}
		mut w := 0
		mut is_float := false
		match parts[0] {
			'1' {
				w = 1
			}
			'2' {
				w = 2
			}
			'4' {
				w = 4
			}
			'8' {
				w = 8
			}
			'f' {
				w = 4
				is_float = true
			}
			'd' {
				w = 8
				is_float = true
			}
			else {
				return new_error(.bad_pattern, 'group type "${parts[0]}" in "${spec}"', 0)
			}
		}

		off := bytes.len
		val := parts[1]
		if val == '*' {
			for _ in 0 .. w {
				bytes << u8(0)
				mask << u8(0)
			}
			continue
		}
		if val.contains('~') {
			rv := val.split('~')
			if rv.len != 2 {
				return new_error(.bad_pattern, 'group range "${val}" in "${spec}"', 0)
			}
			lo := rv[0].f64()
			hi := rv[1].f64()
			for _ in 0 .. w {
				bytes << u8(0)
				mask << u8(0)
			}
			ranges << CellRange{
				off:      off
				lo:       lo
				hi:       hi
				is_float: is_float
				width:    w
			}
			continue
		}
		// exact value cell
		mut cell := []u8{len: w}
		if is_float {
			fv := val.f64()
			if w == 4 {
				encode_f32_le(f32(fv), mut cell)
			} else {
				encode_f64_le(fv, mut cell)
			}
		} else {
			iv := i64(val.i64())
			encode_kind_value_from_i64(w, iv, mut cell)
		}
		bytes << cell
		for _ in 0 .. w {
			mask << u8(0xFF)
		}
	}
	if bytes.len == 0 {
		return new_error(.bad_pattern, 'empty group "${spec}"', 0)
	}
	return ScanPattern{
		bytes:  bytes
		mask:   mask
		ranges: ranges
	}
}
