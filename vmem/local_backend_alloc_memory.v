module vmem

import vmem.sys

// alloc_memory reserves size bytes in the target with the given prot bits
// (see vmem.prot_*); returns the remote address.
pub fn (mut b LocalBackend) alloc_memory(size u64, prot u32) !u64 {
	if !b.attached {
		return new_error(.not_attached, 'alloc_memory size=${size}', 0)
	}
	return sys.alloc_memory(b.handle, size, prot) or {
		return wrap_err(.access_denied, 'alloc_memory size=${size}', err)
	}
}
