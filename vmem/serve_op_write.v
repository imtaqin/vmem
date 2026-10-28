module vmem

// op_write handles the write operation (u64 addr, u32 len, bytes) and returns u32 n.
fn (mut st ServeState) op_write(payload []u8) ![]u8 {
	if !st.attached {
		return new_error(.not_attached, 'agent write', 0)
	}
	if payload.len < 12 {
		return new_error(.protocol, 'write: short payload', 0)
	}
	addr := decode_u64_le(payload[0..8])
	n := int(decode_u32_le(payload[8..12]))
	if n < 0 || payload.len < 12 + n {
		return new_error(.protocol, 'write: truncated payload', 0)
	}
	got := st.backend.write_bytes(addr, payload[12..12 + n]) or {
		return wrap_err(.access_denied, 'agent write 0x${addr:x}', err)
	}
	mut out := []u8{len: 4}
	out[0] = u8(u32(got))
	out[1] = u8(u32(got) >> 8)
	out[2] = u8(u32(got) >> 16)
	out[3] = u8(u32(got) >> 24)
	return out
}
