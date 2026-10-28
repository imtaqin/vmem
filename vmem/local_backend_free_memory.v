module vmem

import vmem.sys

// free_memory releases a range from alloc_memory.
pub fn (mut b LocalBackend) free_memory(addr u64) ! {
	if !b.attached {
		return new_error(.not_attached, 'free_memory 0x${addr:x}', 0)
	}
	sys.free_memory(b.handle, addr) or {
		return wrap_err(.access_denied, 'free_memory 0x${addr:x}', err)
	}
}
