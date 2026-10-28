module vmem

fn test_decode_u32_le() {
	assert decode_u32_le([u8(0x78), 0x56, 0x34, 0x12]) == u32(0x12345678)
}

fn test_decode_u64_le() {
	assert decode_u64_le([u8(0x88), 0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11]) == u64(0x1122334455667788)
}

fn test_encode_u32_le_roundtrip() {
	mut b := []u8{len: 4}
	encode_u32_le(u32(0xDEADBEEF), mut b)
	assert b == [u8(0xEF), 0xBE, 0xAD, 0xDE]
	assert decode_u32_le(b) == u32(0xDEADBEEF)
}

fn test_f32_roundtrip() {
	mut b := []u8{len: 4}
	encode_f32_le(f32(1.5), mut b)
	assert decode_f32_le(b) == f32(1.5)
	// bit-exact NaN payload preservation (LE bit pattern)
	encode_f32_le(f32(-0.0), mut b)
	assert decode_u32_le(b) == u32(0x80000000)
}

fn test_f64_roundtrip() {
	mut b := []u8{len: 8}
	encode_f64_le(f64(-12345.678), mut b)
	assert decode_f64_le(b) == f64(-12345.678)
}
