module vmem

// encode_kind_value_from_i64 writes v into buf (w bytes) little-endian.
fn encode_kind_value_from_i64(w int, v i64, mut buf []u8) {
	match w {
		1 { buf[0] = u8(v) }
		2 { encode_u16_le(u16(v), mut buf) }
		4 { encode_u32_le(u32(v), mut buf) }
		8 { encode_u64_le(u64(v), mut buf) }
		else {}
	}
}
