module vmem

import vmem.sys.remote

// new_remote_backend connects to a device agent and completes the version
// handshake. host is usually 127.0.0.1 behind `adb forward`.
pub fn new_remote_backend(host string, port int) !RemoteBackend {
	strintp_keepalive() // see _strintp_workaround.v (vlib net str() chain)
	mut conn := remote.connect(host, port) or {
		return wrap_err(.transport, 'new_remote_backend ${host}:${port}', err)
	}
	mut r := RemoteBackend{
		conn:    conn
		next_id: 0
	}
	mut hello := []u8{len: 2}
	hello[0] = u8(remote.proto_version)
	hello[1] = 0
	r.next_id++
	remote.send_frame(mut r.conn, remote.op_hello, 0, r.next_id, hello) or {
		return wrap_err(.transport, 'hello send', err)
	}
	f := remote.recv_frame(mut r.conn) or { return wrap_err(.transport, 'hello reply', err) }
	if f.opcode != remote.op_hello_ack || f.payload.len < 2 {
		return new_error(.protocol, 'hello: bad ack opcode=${f.opcode}', 0)
	}
	if f.payload[0] != u8(remote.proto_version) {
		return new_error(.protocol,
			'hello: agent protocol v${f.payload[0]} != ${remote.proto_version}', 0)
	}
	return r
}
