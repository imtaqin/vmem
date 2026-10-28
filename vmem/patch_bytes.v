module vmem

// patch_bytes writes bytes at addr with the page temporarily made writable;
// the previous protection is restored afterwards. Returns bytes written.
pub fn patch_bytes(mut backend MemoryBackend, addr u64, bytes []u8) !int {
	old := backend.protect_memory(addr, u64(bytes.len), prot_read | prot_write | prot_exec) or {
		return wrap_err(.access_denied, 'patch_bytes protect 0x${addr:x}', err)
	}
	n := backend.write_bytes(addr, bytes) or {
		backend.protect_memory(addr, u64(bytes.len), old) or {}
		return wrap_err(.access_denied, 'patch_bytes write 0x${addr:x}', err)
	}
	backend.protect_memory(addr, u64(bytes.len), old) or {}
	return n
}
