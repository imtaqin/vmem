module vmem

import vmem.sys

// current_pid returns the pid of the calling process.
pub fn current_pid() int {
	return sys.current_pid()
}
