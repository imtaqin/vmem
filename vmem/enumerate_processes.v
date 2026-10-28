module vmem

import vmem.sys

// enumerate_processes lists visible OS processes.
pub fn enumerate_processes() ![]ProcessInfo {
	mut c := ProcessCollector{}
	sys.enumerate_processes(mut c) or {
		return wrap_err(.access_denied, 'enumerate_processes', err)
	}
	return c.out
}
