module vmem

// P5 code-tool tests. The hook test is the phase acceptance: install a
// detour, observe redirected behavior, run the original through the
// trampoline, then verify the byte-exact revert.
// x64 machine code executed via remote threads on self.

fn code_page(mut b LocalBackend, body []u8) u64 {
	page := b.alloc_memory(4096, prot_read | prot_write | prot_exec) or { panic(err) }
	mut code := body.clone()
	for _ in 0 .. 26 {
		code << u8(0x90) // NOP padding: room for a 14-byte detour
	}
	patch_bytes(mut b, page, code) or { panic(err) }
	return page
}

fn test_hook_roundtrip_e2e() {
	mut b := new_local_backend(current_pid()) or { panic(err) }
	defer {
		b.detach() or {}
	}
	page := code_page(mut b, [u8(0xB8), 0x07, 0x00, 0x00, 0x00, 0xC3]) // mov eax,7; ret
	hpage := code_page(mut b, [u8(0xB8), 0x09, 0x00, 0x00, 0x00, 0xC3]) // mov eax,9; ret

	// baseline: original behavior
	assert (run_shellcode_at(mut b, page) or { panic(err) }) == 7

	// detour redirects the behavior
	h := install_hook(mut b, .x64, page, hpage, 14) or { panic(err) }
	assert (run_shellcode_at(mut b, page) or { panic(err) }) == 9

	// trampoline runs the stolen original bytes
	assert (run_shellcode_at(mut b, h.trampoline_addr) or { panic(err) }) == 7

	// byte-exact revert restores the original behavior
	remove_hook(mut b, h) or { panic(err) }
	mut cur := []u8{len: 14}
	b.read_bytes(page, mut cur) or { panic(err) }
	assert cur == [u8(0xB8), 0x07, 0x00, 0x00, 0x00, 0xC3, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90,
		0x90, 0x90]
	assert (run_shellcode_at(mut b, page) or { panic(err) }) == 7

	b.free_memory(page) or {}
	b.free_memory(hpage) or {}
}

fn test_run_shellcode_exit_code() {
	mut b := new_local_backend(current_pid()) or { panic(err) }
	defer {
		b.detach() or {}
	}
	code := [u8(0xB8), 0x2A, 0x00, 0x00, 0x00, 0xC3] // mov eax,42; ret
	assert (run_shellcode(mut b, code) or { panic(err) }) == 42
}

fn test_patch_aob() {
	mut mem := []u8{len: 64}
	pat := [u8(0x90), 0x90, 0xC3]
	for i in 0 .. 3 {
		mem[0x10 + i] = pat[i]
	}
	for i in 0 .. 3 {
		mem[0x30 + i] = pat[i]
	}
	mut b := new_fake_backend(3, 0x2000, mem)
	n := patch_aob(mut b, 0x2000, 0x2040, '90 90 C3', [u8(0xCC)], 2, 1) or { panic(err) }
	assert n == 1
	mut buf := []u8{len: 1}
	b.read_bytes(0x2012, mut buf) or { panic(err) }
	assert buf[0] == 0xCC // first hit patched at +2
	b.read_bytes(0x2032, mut buf) or { panic(err) }
	assert buf[0] == 0xC3 // second hit untouched (limit 1)
}

fn test_install_hook_validates_stolen_len() {
	mut b := new_local_backend(current_pid()) or { panic(err) }
	defer {
		b.detach() or {}
	}
	if _ := install_hook(mut b, .x64, 0x1000, 0x2000, 8) {
		assert false, 'expected range error for stolen_len < jmp_len'
	}
}
