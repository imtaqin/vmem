module main

import vmem

// cmd_ptr scans for pointer chains reaching a target:
//   vmem ptr <pid> <target> [--depth N] [--offset N] [--limit N]
fn cmd_ptr(args []string) int {
	pos := positionals(args)
	if pos.len < 2 {
		eprintln('usage: vmem ptr <pid> <target> [--depth N] [--offset N] [--limit N]')
		return 1
	}
	pid := pos[0].int()
	target := parse_addr(pos[1]) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	depth := if flag_val(args, '--depth') == '' { 3 } else { flag_val(args, '--depth').int() }
	offset := if flag_val(args, '--offset') == '' {
		u64(2048)
	} else {
		flag_val(args, '--offset').u64()
	}
	limit := if flag_val(args, '--limit') == '' { 64 } else { flag_val(args, '--limit').int() }
	mut b := vmem.new_local_backend(pid) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	defer {
		b.detach() or {}
	}
	paths := vmem.pointer_scan(mut b, target, offset, depth, limit, vmem.ScanFilter{}) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	println('paths: ${paths.len}')
	for p in paths {
		mut s := '0x${p.base:x}'
		for off in p.offsets {
			s += ' -> ${off}'
		}
		v := vmem.resolve_pointer(mut b, p) or { u64(0) }
		println('${s}\t=> 0x${v:x}')
	}
	return 0
}
