module sys

import os

// enumerate_threads lists the tasks of a pid via /proc/<pid>/task.
pub fn enumerate_threads(h voidptr) ![]int {
	pid := pid_from_handle(h)
	entries := os.ls('/proc/${pid}/task') or {
		return error_with_code('enumerate_threads: ${err.msg()}', 0)
	}
	mut out := []int{}
	for e in entries {
		tid := e.int()
		if tid > 0 {
			out << tid
		}
	}
	return out
}
