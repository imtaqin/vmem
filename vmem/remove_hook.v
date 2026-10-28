module vmem

// remove_hook restores the stolen bytes (byte-exact revert) and frees the
// trampoline.
pub fn remove_hook(mut backend MemoryBackend, h Hook) ! {
	patch_bytes(mut backend, h.addr, h.stolen) or {
		return wrap_err(.access_denied, 'remove_hook restore 0x${h.addr:x}', err)
	}
	backend.free_memory(h.trampoline_addr) or {}
}
