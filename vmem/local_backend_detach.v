module vmem

import vmem.sys

// detach closes the OS handle; safe to call multiple times.
pub fn (mut b LocalBackend) detach() ! {
	if b.attached {
		sys.close_process(b.handle)
		b.attached = false
		b.handle = unsafe { nil }
	}
}
