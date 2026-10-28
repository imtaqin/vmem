module vmem

import vmem.sys

// run_shellcode_at runs a remote thread at addr and returns its exit code.
// Local-only (remote thread ops are a LocalBackend capability; the agent
// counterpart lands with the P5b agent work).
pub fn run_shellcode_at(mut b LocalBackend, addr u64) !u64 {
	if !b.attached {
		return new_error(.not_attached, 'run_shellcode_at 0x${addr:x}', 0)
	}
	th := sys.create_thread(b.handle, addr, 0) or {
		return wrap_err(.access_denied, 'run_shellcode_at 0x${addr:x}', err)
	}
	sys.wait_thread(th, 5000) or {
		sys.close_process(th)
		return wrap_err(.access_denied, 'run_shellcode_at wait 0x${addr:x}', err)
	}
	code := sys.thread_exit_code(th) or {
		sys.close_process(th)
		return wrap_err(.access_denied, 'run_shellcode_at exit code', err)
	}
	sys.close_process(th)
	return code
}
