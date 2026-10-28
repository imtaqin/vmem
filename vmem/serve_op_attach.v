module vmem

// op_attach handles the attach operation (i32 pid payload).
fn (mut st ServeState) op_attach(payload []u8) ![]u8 {
	if payload.len < 4 {
		return new_error(.protocol, 'attach: short payload', 0)
	}
	pid := int(i32(decode_u32_le(payload[0..4])))
	st.backend.attach(pid) or { return wrap_err(.access_denied, 'agent attach pid=${pid}', err) }
	st.attached = true
	return []u8{}
}
