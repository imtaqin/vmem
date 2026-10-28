module vmem

// op_read handles the read operation (u64 addr, u32 len) and returns u32 n, bytes.
fn (mut st ServeState) op_read(payload []u8) ![]u8 {
	if !st.attached {
		return new_error(.not_attached, 'agent read', 0)
	}
	if payload.len < 12 {
		return new_error(.protocol, 'read: short payload', 0)
	}
	addr := decode_u64_le(payload[0..8])
	want := int(decode_u32_le(payload[8..12]))
	if want < 0 || want > 64 * 1024 * 1024 {
		return new_error(.range, 'read len=${want}', 0)
	}
	mut buf := []u8{len: want}
	n := st.backend.read_bytes(addr, mut buf) or {
		return wrap_err(.access_denied, 'agent read 0x${addr:x}', err)
	}
	mut out := []u8{len: 4 + n}
	out[0] = u8(u32(n))
	out[1] = u8(u32(n) >> 8)
	out[2] = u8(u32(n) >> 16)
	out[3] = u8(u32(n) >> 24)
	for i in 0 .. n {
		out[4 + i] = buf[i]
	}
	return out
}
