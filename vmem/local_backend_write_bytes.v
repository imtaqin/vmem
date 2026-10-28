module vmem

import vmem.sys

// write_bytes writes buf at addr; returns bytes written.
pub fn (mut b LocalBackend) write_bytes(addr u64, buf []u8) !int {
	if !b.attached {
		return new_error(.not_attached, 'write_bytes addr=0x${addr:x}', 0)
	}
	n := sys.write_bytes(b.handle, addr, buf) or {
		kind := if err.code() == 299 { ErrKind.short_io } else { ErrKind.access_denied }
		return wrap_err(kind, 'write_bytes addr=0x${addr:x}', err)
	}
	return n
}
