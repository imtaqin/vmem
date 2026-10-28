module vmem

import vmem.sys

// read_bytes reads up to buf.len bytes at addr; returns bytes read.
pub fn (mut b LocalBackend) read_bytes(addr u64, mut buf []u8) !int {
	if !b.attached {
		return new_error(.not_attached, 'read_bytes addr=0x${addr:x}', 0)
	}
	n := sys.read_bytes(b.handle, addr, mut buf) or {
		kind := if err.code() == 299 { ErrKind.short_io } else { ErrKind.access_denied }
		return wrap_err(kind, 'read_bytes addr=0x${addr:x}', err)
	}
	return n
}
