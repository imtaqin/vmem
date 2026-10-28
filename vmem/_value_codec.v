module vmem

// Internal little-endian value codec (one concern; AGENTS.md §3).
// Decode/encode is LE on all supported targets (AGENTS.md §4).

fn decode_u16_le(b []u8) u16 {
	return u16(b[0]) | (u16(b[1]) << 8)
}

fn decode_u32_le(b []u8) u32 {
	return u32(b[0]) | (u32(b[1]) << 8) | (u32(b[2]) << 16) | (u32(b[3]) << 24)
}

fn decode_u64_le(b []u8) u64 {
	mut v := u64(0)
	for i in 0 .. 8 {
		v |= u64(b[i]) << (8 * u64(i))
	}
	return v
}

fn encode_u16_le(v u16, mut b []u8) {
	b[0] = u8(v)
	b[1] = u8(v >> 8)
}

fn encode_u32_le(v u32, mut b []u8) {
	b[0] = u8(v)
	b[1] = u8(v >> 8)
	b[2] = u8(v >> 16)
	b[3] = u8(v >> 24)
}

fn encode_u64_le(v u64, mut b []u8) {
	for i in 0 .. 8 {
		b[i] = u8(v >> (8 * u64(i)))
	}
}

fn decode_f32_le(b []u8) f32 {
	u := decode_u32_le(b)
	return unsafe { *(&f32(&u)) }
}

fn decode_f64_le(b []u8) f64 {
	u := decode_u64_le(b)
	return unsafe { *(&f64(&u)) }
}

fn encode_f32_le(v f32, mut b []u8) {
	u := unsafe { *(&u32(&v)) }
	encode_u32_le(u, mut b)
}

fn encode_f64_le(v f64, mut b []u8) {
	u := unsafe { *(&u64(&v)) }
	encode_u64_le(u, mut b)
}
