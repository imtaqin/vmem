module vmem

import vmem.sys

// protect_memory changes page protection; returns the previous prot bits.
pub fn (mut b LocalBackend) protect_memory(addr u64, size u64, prot u32) !u32 {
	if !b.attached {
		return new_error(.not_attached, 'protect_memory 0x${addr:x}', 0)
	}
	return sys.protect_memory(b.handle, addr, size, prot) or {
		return wrap_err(.access_denied, 'protect_memory 0x${addr:x}', err)
	}
}
