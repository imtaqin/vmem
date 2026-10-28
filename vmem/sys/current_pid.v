module sys

import os

// current_pid returns the pid of the calling process.
pub fn current_pid() int {
	return os.getpid()
}
