module remote

import net
import encoding.binary

// send_frame writes one framed message (blocking, exact-length).
pub fn send_frame(mut c net.TcpConn, opcode u16, flags u16, request_id u64, payload []u8) ! {
	total := u32(12 + payload.len)
	mut hdr := []u8{len: 16}
	binary.little_endian_put_u32(mut hdr[0..4], total)
	binary.little_endian_put_u16(mut hdr[4..6], opcode)
	binary.little_endian_put_u16(mut hdr[6..8], flags)
	binary.little_endian_put_u64(mut hdr[8..16], request_id)
	c.write(hdr) or { return error_with_code('remote send header: ${err.msg()}', err.code()) }
	if payload.len > 0 {
		c.write(payload) or {
			return error_with_code('remote send payload: ${err.msg()}', err.code())
		}
	}
}
