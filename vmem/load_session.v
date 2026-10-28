module vmem

import os

// load_session restores a ScanSession written by save_session.
pub fn load_session(path string) !ScanSession {
	content := os.read_file(path) or {
		return wrap_err(.access_denied, 'load_session ${path}', err)
	}
	all := content.bytes()
	if all.len < 15 {
		return new_error(.protocol, 'load_session ${path}: truncated', 0)
	}
	mut s := ScanSession{
		kind:   unsafe { ValueKind(all[0]) }
		op:     unsafe { CompareOp(all[1]) }
		stride: int(all[2])
		align:  decode_u64_le(all[3..11])
	}
	hits := decode_hit_list(all[11..all.len]) or {
		return wrap_err(.protocol, 'load_session ${path} hits', err)
	}
	s.addresses = hits.addresses
	s.prev_raw = hits.raw
	s.stable = hits.stable
	s.scans = 1
	s.total_hits = hits.addresses.len
	s.first_raw = hits.raw.clone()
	// trailing first-value hit list
	used := 11 + 8 + hits.addresses.len * 12 + hits.addresses.len * hits.stride
	if all.len >= used + 4 {
		flen := int(decode_u32_le(all[used..used + 4]))
		if flen > 8 && all.len >= used + 4 + flen {
			if first := decode_hit_list(all[used + 4..used + 4 + flen]) {
				if first.raw.len == s.prev_raw.len {
					s.first_raw = first.raw
				}
			}
		}
	}
	return s
}
