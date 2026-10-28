module vmem

import vmem.sys

// inject_dll loads a DLL into the target via a remote LoadLibraryW thread
// (Windows DLL injection model). Returns the remote module handle the
// loader produced.
pub fn inject_dll(mut b LocalBackend, dll_path string) !u64 {
	if !b.attached {
		return new_error(.not_attached, 'inject_dll ${dll_path}', 0)
	}
	loader := sys.find_export('kernel32.dll', 'LoadLibraryW') or {
		return wrap_err(.unsupported, 'inject_dll find LoadLibraryW', err)
	}
	// remote buffer: UTF-16LE path + terminator
	wpath := encode_text(dll_path, .utf16le)
	mut buf := []u8{len: wpath.len + 2}
	for i in 0 .. wpath.len {
		buf[i] = wpath[i]
	}
	page := b.alloc_memory(u64(buf.len), prot_read | prot_write) or {
		return wrap_err(.unsupported, 'inject_dll alloc', err)
	}
	patch_bytes(mut b, page, buf) or {
		b.free_memory(page) or {}
		return err
	}
	th := sys.create_thread(b.handle, loader, page) or {
		b.free_memory(page) or {}
		return wrap_err(.access_denied, 'inject_dll thread', err)
	}
	sys.wait_thread(th, 5000) or {
		sys.close_process(th)
		b.free_memory(page) or {}
		return wrap_err(.access_denied, 'inject_dll wait', err)
	}
	code := sys.thread_exit_code(th) or {
		sys.close_process(th)
		b.free_memory(page) or {}
		return wrap_err(.access_denied, 'inject_dll exit code', err)
	}
	sys.close_process(th)
	b.free_memory(page) or {}
	return code
}
