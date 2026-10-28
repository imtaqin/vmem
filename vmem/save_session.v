module vmem

import os

// save_session persists a ScanSession to path: 11-byte header
// (kind, op, stride, align u64) then the hit list (encode_hit_list) and a
// trailing first-value hit list. Used by the CLI between commands.
pub fn save_session(s &ScanSession, path string) !int {
	mut head := []u8{len: 11}
	head[0] = u8(s.kind)
	head[1] = u8(s.op)
	head[2] = u8(s.stride)
	encode_u64_le(s.align, mut head[3..11])
	body := encode_hit_list(s.addresses, s.prev_raw, s.stable, s.stride)
	first := encode_hit_list(s.addresses, s.first_raw, s.stable, s.stride)
	mut all := head.clone()
	all << body
	mut flen := []u8{len: 4}
	encode_u32_le(u32(first.len), mut flen)
	all << flen
	all << first
	os.write_file_array(path, all) or {
		return wrap_err(.access_denied, 'save_session ${path}', err)
	}
	return all.len
}
