module vmem

// wire_error encodes an error into an ERROR payload: i32 code | u16 len | msg.
// Code mirrors decode_wire_error on the client side.
fn wire_error(err IError) []u8 {
	mut kind := ErrKind.protocol
	if err is VmError {
		kind = err.kind
	}
	code := match kind {
		.not_attached { 1 }
		.access_denied { 2 }
		.short_io { 3 }
		.unsupported { 4 }
		.range { 5 }
		.state { 6 }
		else { 0 }
	}

	msg := wire_str(err.msg())
	mut b := []u8{len: 4 + msg.len}
	b[0] = u8(u32(code))
	b[1] = u8(u32(code) >> 8)
	b[2] = u8(u32(code) >> 16)
	b[3] = u8(u32(code) >> 24)
	for i in 0 .. msg.len {
		b[4 + i] = msg[i]
	}
	return b
}
