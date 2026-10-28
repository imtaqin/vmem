module main

import vmem
import json

// cmd_maps lists the committed memory regions of a process.
fn cmd_maps(args []string) int {
	pos := positionals(args)
	if pos.len < 1 {
		eprintln('usage: vmem maps <pid> [--json]')
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
	regions := b.enumerate_regions() or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	if has_flag(args, '--json') {
		println(json.encode(regions))
		return 0
	}
	for r in regions {
		println('0x${r.base:x}\t0x${r.size:x}\t${r.prot}\t${r.class}\t${r.name}')
	}
	return 0
}
