module vmem

import vmem.sys

// suspend pauses every thread of the target.
pub fn (mut b LocalBackend) suspend() ! {
	if !b.attached {
		return new_error(.not_attached, 'suspend', 0)
	}
	sys.suspend_process(b.handle) or { return wrap_err(.access_denied, 'suspend', err) }
}
