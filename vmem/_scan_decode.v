module vmem

// Internal scan value decoding (one concern; AGENTS.md §3).
// Integer kinds decode as sign-extended i64 (byte/word/dword exact; qword
// values above i64 max are a documented v1 limitation). Float kinds decode
// to f64 exactly (f32 promotes losslessly).

fn decode_kind_int(k ValueKind, b []u8) i64 {
	match k {
		.byte { return i64(i8(b[0])) }
		.word { return i64(i16(decode_u16_le(b))) }
		.dword { return i64(i32(decode_u32_le(b))) }
		.qword { return i64(decode_u64_le(b)) }
		else { return 0 }
	}
}

// decode_width_int sign-extends a raw little-endian integer of w bytes.
fn decode_width_int(w int, b []u8) i64 {
	match w {
		1 { return i64(i8(b[0])) }
		2 { return i64(i16(decode_u16_le(b))) }
		4 { return i64(i32(decode_u32_le(b))) }
		8 { return i64(decode_u64_le(b)) }
		else { return 0 }
	}
}

fn decode_kind_num(k ValueKind, b []u8) f64 {
	match k {
		.float { return f64(decode_f32_le(b)) }
		.double { return decode_f64_le(b) }
		else { return f64(decode_kind_int(k, b)) }
	}
}

// encode_kind_value writes v into buf (kind width) little-endian.
fn encode_kind_value(k ValueKind, v f64, mut buf []u8) {
	match k {
		.byte { buf[0] = u8(i64(v)) }
		.word { encode_u16_le(u16(i64(v)), mut buf) }
		.dword { encode_u32_le(u32(i64(v)), mut buf) }
		.qword { encode_u64_le(u64(i64(v)), mut buf) }
		.float { encode_f32_le(f32(v), mut buf) }
		.double { encode_f64_le(v, mut buf) }
		else {}
	}
}
