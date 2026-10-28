module vmem

// install_hook detours addr to hook_addr (CE trampoline-hook model):
// stolen_len bytes at addr move to an executable trampoline that jumps back
// to addr+stolen_len; addr receives an absolute jump to hook_addr.
// stolen_len must cover the whole instructions overwritten (>= jmp length:
// 14 on x64, 16 on arm64) — instruction-boundary rounding is the caller's.
pub fn install_hook(mut backend MemoryBackend, arch HookArch, addr u64, hook_addr u64, stolen_len int) !Hook {
	jl := jmp_len_for(arch)
	if stolen_len < jl {
		return new_error(.range, 'install_hook stolen_len=${stolen_len} < ${jl}', 0)
	}
	mut stolen := []u8{len: stolen_len}
	n := backend.read_bytes(addr, mut stolen) or {
		return wrap_err(.access_denied, 'install_hook read 0x${addr:x}', err)
	}
	if n != stolen_len {
		return new_error(.short_io, 'install_hook read 0x${addr:x}', 0)
	}
	// trampoline: stolen bytes + jump back into the function tail
	tramp := backend.alloc_memory(u64(stolen_len + jl), prot_read | prot_write | prot_exec) or {
		return wrap_err(.unsupported, 'install_hook trampoline alloc', err)
	}
	mut body := stolen.clone()
	body << jmp_abs(arch, addr + u64(stolen_len))
	patch_bytes(mut backend, tramp, body) or {
		backend.free_memory(tramp) or {}
		return err
	}
	// detour at the original address
	patch_bytes(mut backend, addr, jmp_abs(arch, hook_addr)) or {
		backend.free_memory(tramp) or {}
		return err
	}
	return Hook{
		addr:            addr
		hook_addr:       hook_addr
		trampoline_addr: tramp
		arch:            arch
		stolen:          stolen
		jmp_len:         jl
	}
}
