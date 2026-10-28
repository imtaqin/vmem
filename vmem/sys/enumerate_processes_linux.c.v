module sys

import os

// enumerate_processes lists /proc entries (pid + comm name).
pub fn enumerate_processes(mut sink ProcessSink) ! {
	entries := os.ls('/proc') or { return error_with_code('enumerate_processes: ${err.msg()}', 0) }
	for e in entries {
		pid := e.int()
		if pid <= 0 {
			continue
		}
		name := os.read_file('/proc/${e}/comm') or { '' }
		sink.push(pid, name.trim_space(), '')
	}
}
