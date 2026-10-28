module vmem

import vmem.sys.remote

// rpc performs one request/response exchange and returns the response
// payload. Agent-side errors arrive as op_error frames and map to VmError.
fn (mut r RemoteBackend) rpc(op u16, payload []u8) ![]u8 {
	r.next_id++
	id := r.next_id
	remote.send_frame(mut r.conn, op, 0, id, payload) or {
		return wrap_err(.transport, 'rpc op=${op}', err)
	}
	f := remote.recv_frame(mut r.conn) or { return wrap_err(.transport, 'rpc op=${op} reply', err) }
	if f.request_id != id {
		return new_error(.protocol, 'rpc op=${op}: reply id ${f.request_id} != ${id}', 0)
	}
	if f.opcode == remote.op_error {
		return decode_wire_error(f.payload)
	}
	if f.opcode != op | remote.flag_response {
		return new_error(.protocol, 'rpc op=${op}: unexpected opcode ${f.opcode}', 0)
	}
	return f.payload
}

// decode_wire_error turns an ERROR payload (i32 code, str msg) into VmError.
fn decode_wire_error(b []u8) VmError {
	code := int(i32(decode_u32_le(b[0..4])))
	msg := if b.len > 6 {
		n := int(decode_u16_le(b[4..6]))
		if b.len >= 6 + n {
			b[6..6 + n].bytestr()
		} else {
			'agent error'
		}
	} else {
		'agent error'
	}
	kind := match code {
		1 { ErrKind.not_attached }
		2 { ErrKind.access_denied }
		3 { ErrKind.short_io }
		4 { ErrKind.unsupported }
		5 { ErrKind.range }
		6 { ErrKind.state }
		else { ErrKind.protocol }
	}

	return new_error(kind, msg, 0)
}
