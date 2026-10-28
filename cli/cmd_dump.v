module main

import vmem

// cmd_dump dumps a memory range: vmem dump <pid> <start> <end> <file> [--hex].
fn cmd_dump(args []string) int {
	pos := positionals(args)
	if pos.len < 4 {
		eprintln('usage: vmem dump <pid> <start> <end> <file> [--hex]')
		return 1
	}
	pid := pos[0].int()
	start := parse_addr(pos[1]) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	end := parse_addr(pos[2]) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	mut b := vmem.new_local_backend(pid) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	defer {
		b.detach() or {}
	}
	n := if has_flag(args, '--hex') {
		vmem.dump_hex(mut b, pos[3], start, end, 16) or {
			eprintln('error: ${err.msg()}')
			return 1
		}
	} else {
		vmem.dump_memory(mut b, pos[3], start, end) or {
			eprintln('error: ${err.msg()}')
			return 1
		}
	}
	println('dumped ${n} bytes to ${pos[3]}')
	return 0
}
