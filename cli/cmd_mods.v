module main

import vmem
import json

// cmd_mods lists the loaded modules of a process.
fn cmd_mods(args []string) int {
	pos := positionals(args)
	if pos.len < 1 {
		eprintln('usage: vmem mods <pid> [--json]')
		return 1
	}
	pid := pos[0].int()
	mut b := vmem.new_local_backend(pid) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	defer {
		b.detach() or {}
	}
	mods := b.enumerate_modules() or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	if has_flag(args, '--json') {
		println(json.encode(mods))
		return 0
	}
	for m in mods {
		println('0x${m.base:x}\t0x${m.size:x}\t${m.name}\t${m.path}')
	}
	return 0
}
