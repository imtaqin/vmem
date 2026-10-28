module vmem

// edit_all writes value to every hit of the session (CE edit-all semantics).
// For pattern sessions (aob/text/group) it writes the pattern bytes
// (GameGuardian editAll model). Returns the number of hits written.
pub fn edit_all(mut backend MemoryBackend, s &ScanSession, value f64) !int {
	if s.scans == 0 {
		return new_error(.state, 'edit_all before scan_first', 0)
	}
	mut count := 0
	if s.kind == .aob || s.kind == .text {
		for addr in s.addresses {
			n := backend.write_bytes(addr, s.pattern.bytes) or { continue }
			if n == s.pattern.bytes.len {
				count++
			}
		}
		return count
	}
	for addr in s.addresses {
		edit_value(mut backend, s.kind, addr, value) or { continue }
		count++
	}
	return count
}
