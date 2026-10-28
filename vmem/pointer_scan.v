module vmem

// pointer_scan finds pointer chains that reach target within max_offset
// bytes per level, up to max_depth dereferences (CE pointer scan model;
// defaults from CE/GG: offset 2048, depth 5). Every hit emits a path whose
// base is the deepest slot and whose offsets run deepest-first
// (resolve_pointer walks them back to target).
//
// The scan is recursive range-scan based: cost grows with depth; cap with
// limit (paths) and keep depth small on huge targets.
pub fn pointer_scan(mut backend MemoryBackend, target u64, max_offset u64, max_depth int, limit int, filter ScanFilter) ![]PointerPath {
	depth := if max_depth <= 0 { 1 } else { max_depth }
	cap := if limit <= 0 { 1024 } else { limit }
	mut paths := []PointerPath{}
	mut chain := []i64{}
	collect_pointers(mut backend, target, max_offset, depth, 0, mut chain, mut paths, cap, filter)
	return paths
}
