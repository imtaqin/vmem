module vmem

// result_count returns the number of hits currently kept in the session.
pub fn result_count(s &ScanSession) int {
	return s.addresses.len
}
