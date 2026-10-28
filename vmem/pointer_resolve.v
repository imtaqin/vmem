module vmem

// resolve_pointer walks a chain: cur = base; per offset: cur = *cur + offset.
// A module name makes base relative to that image (CE module+offset model).
// Returns the resolved address (the address the chain points to).
pub fn resolve_pointer(mut backend MemoryBackend, p PointerPath) !u64 {
	mut base := p.base
	if p.module != '' {
		mods := backend.enumerate_modules() or {
			return wrap_err(.access_denied, 'resolve_pointer modules', err)
		}
		mut found := false
		for m in mods {
			if m.name.to_lower() == p.module.to_lower() {
				base = m.base + p.base
				found = true
				break
			}
		}
		if !found {
			return new_error(.range, 'resolve_pointer: module ${p.module} not found', 0)
		}
	}
	mut cur := base
	for off in p.offsets {
		mut buf := []u8{len: 8}
		n := backend.read_bytes(cur, mut buf) or {
			return wrap_err(.access_denied, 'resolve_pointer 0x${cur:x}', err)
		}
		if n != 8 {
			return new_error(.short_io, 'resolve_pointer 0x${cur:x} got=${n}/8', 0)
		}
		cur = u64(i64(decode_u64_le(buf)) + off)
	}
	return cur
}
