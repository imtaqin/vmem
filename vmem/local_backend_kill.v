module vmem

import vmem.sys

// kill terminates the target process.
pub fn (mut b LocalBackend) kill() ! {
	if !b.attached {
		return new_error(.not_attached, 'kill', 0)
	}
	sys.kill_process(b.handle, 1) or { return wrap_err(.access_denied, 'kill', err) }
}
