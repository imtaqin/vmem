module remote

import net
import encoding.binary

// recv_frame reads one framed message (blocking, exact-length).
pub fn recv_frame(mut c net.TcpConn) !Frame {
	mut hdr := []u8{len: 16}
	read_exact(mut c, mut hdr) or {
		return error_with_code('remote recv header: ${err.msg()}', err.code())
	}
	total := binary.little_endian_u32(hdr[0..4])
	if total < 12 || total > max_payload + 12 {
		return error_with_code('remote frame size ${total}', 0)
	}
	opcode := binary.little_endian_u16(hdr[4..6])
	flags := binary.little_endian_u16(hdr[6..8])
	request_id := binary.little_endian_u64(hdr[8..16])
	plen := int(total - 12)
	mut payload := []u8{len: plen}
	if plen > 0 {
		read_exact(mut c, mut payload) or {
			return error_with_code('remote recv payload: ${err.msg()}', err.code())
		}
	}
	return Frame{
		opcode:     opcode
		flags:      flags
		request_id: request_id
		payload:    payload
	}
}

// read_exact fills buf completely or errors (short reads loop).
fn read_exact(mut c net.TcpConn, mut buf []u8) ! {
	mut got := 0
	for got < buf.len {
		n := c.read(mut buf[got..buf.len]) or {
			return error_with_code('remote read: ${err.msg()}', err.code())
		}
		if n <= 0 {
			return error('remote read: connection closed')
		}
		got += n
	}
}
