module vmem

// parse_group_gg parses a GameGuardian-style group: cells separated by `;`,
// all cells of one width (from kind), optional `::N` total-size suffix
// (the group is front-packed and padded with trailing wildcards to N bytes,
// our documented semantics). Cell values: a number, `*` or `0~~0` (any),
// `a~b` (value range).
// Example: "6~7;7;1~2;0;0::29".
pub fn parse_group_gg(spec string, kind ValueKind) !ScanPattern {
	w := kind_size(kind)
	if w == 0 {
		return new_error(.bad_pattern, 'group kind ${kind} needs scalar width', 0)
	}
	mut body := spec
	mut total := 0
	if spec.contains('::') {
		parts := spec.split('::')
		if parts.len != 2 {
			return new_error(.bad_pattern, 'group "${spec}"', 0)
		}
		body = parts[0]
		total = parts[1].int()
		if total <= 0 {
			return new_error(.bad_pattern, 'group size "${parts[1]}" in "${spec}"', 0)
		}
	}
	mut bytes := []u8{}
	mut mask := []u8{}
	mut ranges := []CellRange{}
	is_float := kind == .float || kind == .double
	for tok in body.split(';') {
		t := tok.trim_space()
		if t == '' {
			continue
		}
		off := bytes.len
		if t == '*' || t == '0~~0' {
			for _ in 0 .. w {
				bytes << u8(0)
				mask << u8(0)
			}
			continue
		}
		if t.contains('~') {
			rv := t.split('~')
			if rv.len != 2 {
				return new_error(.bad_pattern, 'group cell "${t}" in "${spec}"', 0)
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
		mut cell := []u8{len: w}
		if is_float {
			fv := t.f64()
			if w == 4 {
				encode_f32_le(f32(fv), mut cell)
			} else {
				encode_f64_le(fv, mut cell)
			}
		} else {
			encode_kind_value_from_i64(w, i64(t.i64()), mut cell)
		}
		bytes << cell
		for _ in 0 .. w {
			mask << u8(0xFF)
		}
	}
	if bytes.len == 0 {
		return new_error(.bad_pattern, 'empty group "${spec}"', 0)
	}
	if total > 0 {
		if total < bytes.len {
			return new_error(.bad_pattern, 'group size ${total} < ${bytes.len} in "${spec}"', 0)
		}
		for bytes.len < total {
			bytes << u8(0)
			mask << u8(0)
		}
	}
	return ScanPattern{
		bytes:  bytes
		mask:   mask
		ranges: ranges
	}
}
