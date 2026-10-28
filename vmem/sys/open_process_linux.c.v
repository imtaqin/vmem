module sys

import os

// open_process validates the target and returns a pid-based pseudo-handle
// (process_vm_* and /proc paths take the pid directly).
pub fn open_process(pid int) !voidptr {
	if pid <= 0 || !os.exists('/proc/${pid}') {
		return error_with_code('open_process: no /proc/${pid}', 0)
	}
	return pseudo_handle(pid)
}
