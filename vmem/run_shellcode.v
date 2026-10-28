module vmem

// run_shellcode allocates an RWX page, copies code in, runs it as a remote
// thread and returns its exit code. The page is freed afterwards.
// Local-only (see run_shellcode_at).
pub fn run_shellcode(mut b LocalBackend, code []u8) !u64 {
	page := b.alloc_memory(u64(code.len), prot_read | prot_write | prot_exec) or {
		return wrap_err(.unsupported, 'run_shellcode alloc', err)
	}
	patch_bytes(mut b, page, code) or {
		b.free_memory(page) or {}
		return err
	}
	exit_code := run_shellcode_at(mut b, page) or {
		b.free_memory(page) or {}
		return err
	}
	b.free_memory(page) or {}
	return exit_code
}
