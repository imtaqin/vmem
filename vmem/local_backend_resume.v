module vmem

import vmem.sys

// resume resumes every thread of the target.
pub fn (mut b LocalBackend) resume() ! {
	if !b.attached {
		return new_error(.not_attached, 'resume', 0)
	}
	sys.resume_process(b.handle) or { return wrap_err(.access_denied, 'resume', err) }
}
