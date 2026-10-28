module main

import vmem
import json

// cmd_ps lists visible processes.
fn cmd_ps(args []string) int {
	procs := vmem.enumerate_processes() or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	if has_flag(args, '--json') {
		println(json.encode(procs))
		return 0
	}
	for p in procs {
		println('${p.pid}\t${p.name}')
	}
	return 0
}
