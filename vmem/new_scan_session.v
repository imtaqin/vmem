module vmem

// new_scan_session returns an empty session; scans reset it per pass.
pub fn new_scan_session() ScanSession {
	return ScanSession{}
}
