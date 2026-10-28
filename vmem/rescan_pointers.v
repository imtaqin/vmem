module vmem

// rescan_pointers keeps only paths that still resolve to new_target
// (CE rescan model: filter after the target relocated).
pub fn rescan_pointers(mut backend MemoryBackend, paths []PointerPath, new_target u64) ![]PointerPath {
	mut out := []PointerPath{}
	for p in paths {
		v := resolve_pointer(mut backend, p) or { continue }
		if v == new_target {
			out << p
		}
	}
	return out
}
