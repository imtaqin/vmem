module vmem

import vmem.sys.remote

// write_bytes writes target memory through the agent.
pub fn (mut r RemoteBackend) write_bytes(addr u64, buf []u8) !int {
	mut req := []u8{len: 12 + buf.len}
	for i in 0 .. 8 {
		req[i] = u8(addr >> (8 * u64(i)))
	}
	req[8] = u8(u32(buf.len))
	req[9] = u8(u32(buf.len) >> 8)
	req[10] = u8(u32(buf.len) >> 16)
	req[11] = u8(u32(buf.len) >> 24)
	for i in 0 .. buf.len {
		req[12 + i] = buf[i]
	}
	resp := r.rpc(remote.op_write, req) or {
		return wrap_err(.access_denied, 'remote write 0x${addr:x}', err)
	}
	if resp.len < 4 {
		return new_error(.protocol, 'remote write: short reply', 0)
	}
	return int(decode_u32_le(resp[0..4]))
}
