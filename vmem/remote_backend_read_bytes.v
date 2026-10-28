module vmem

import vmem.sys.remote

// read_bytes reads target memory through the agent.
pub fn (mut r RemoteBackend) read_bytes(addr u64, mut buf []u8) !int {
	mut req := []u8{len: 12}
	req[0] = u8(addr)
	req[1] = u8(addr >> 8)
	req[2] = u8(addr >> 16)
	req[3] = u8(addr >> 24)
	req[4] = u8(addr >> 32)
	req[5] = u8(addr >> 40)
	req[6] = u8(addr >> 48)
	req[7] = u8(addr >> 56)
	req[8] = u8(u32(buf.len))
	req[9] = u8(u32(buf.len) >> 8)
	req[10] = u8(u32(buf.len) >> 16)
	req[11] = u8(u32(buf.len) >> 24)
	resp := r.rpc(remote.op_read, req) or {
		return wrap_err(.access_denied, 'remote read 0x${addr:x}', err)
	}
	if resp.len < 4 {
		return new_error(.protocol, 'remote read: short reply', 0)
	}
	n := int(decode_u32_le(resp[0..4]))
	if n < 0 || n > buf.len || resp.len < 4 + n {
		return new_error(.protocol, 'remote read: bad count ${n}', 0)
	}
	for i in 0 .. n {
		buf[i] = resp[4 + i]
	}
	return n
}
