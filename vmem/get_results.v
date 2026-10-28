module vmem

// get_results returns a snapshot of the session hits starting at offset.
// value is the decoded byte set saved at the most recent scan, prev is the
// value from the first scan; raw is the current saved bytes.
pub fn get_results(s &ScanSession, offset int, limit int) []ResultEntry {
	mut out := []ResultEntry{}
	if s.scans == 0 || s.addresses.len == 0 {
		return out
	}
	sz := if s.stride > 0 { s.stride } else { kind_size(s.kind) }
	end := if limit <= 0 || offset + limit > s.addresses.len {
		s.addresses.len
	} else {
		offset + limit
	}
	for i in offset .. end {
		cur := s.prev_raw[i * sz..(i + 1) * sz]
		first := s.first_raw[i * sz..(i + 1) * sz]
		out << ResultEntry{
			address: s.addresses[i]
			kind:    s.kind
			value:   decode_kind_num(s.kind, cur)
			prev:    decode_kind_num(s.kind, first)
			raw:     cur.clone()
			stable:  int(s.stable[i])
		}
	}
	return out
}
