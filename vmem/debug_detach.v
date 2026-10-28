module vmem

import vmem.sys

// detach stops debugging; the target keeps running.
pub fn (mut s DebugSession) detach() ! {
	if s.attached {
		sys.debug_detach(s.pid) or {
			return wrap_err(.access_denied, 'debug_detach pid=${s.pid}', err)
		}
		s.attached = false
	}
}
