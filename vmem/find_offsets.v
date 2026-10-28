module vmem

// find_offsets compares two same-sized blocks of target memory and returns
// the byte offsets where they differ (CE structure-dissect model: the
// differing offsets are candidate per-instance fields).
pub fn find_offsets(mut backend MemoryBackend, addr_a u64, addr_b u64, size int) ![]int {
	if size <= 0 || size > 1024 * 1024 {
		return new_error(.range, 'find_offsets size=${size}', 0)
	}
	mut a := []u8{len: size}
	mut b := []u8{len: size}
	na := backend.read_bytes(addr_a, mut a) or {
		return wrap_err(.access_denied, 'find_offsets 0x${addr_a:x}', err)
	}
	nb := backend.read_bytes(addr_b, mut b) or {
		return wrap_err(.access_denied, 'find_offsets 0x${addr_b:x}', err)
	}
	if na != size || nb != size {
		return new_error(.short_io, 'find_offsets got ${na}/${nb} of ${size}', 0)
	}
	mut out := []int{}
	for i in 0 .. size {
		if a[i] != b[i] {
			out << i
		}
	}
	return out
}
