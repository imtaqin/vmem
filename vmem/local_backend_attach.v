module vmem

import vmem.sys

// attach opens the OS handle for pid (closes any previous handle).
pub fn (mut b LocalBackend) attach(pid int) ! {
	if b.attached {
		sys.close_process(b.handle)
		b.attached = false
	}
	h := sys.open_process(pid) or { return wrap_err(.access_denied, 'attach pid=${pid}', err) }
	b.handle = h
	b.target_pid = pid
	b.attached = true
}
