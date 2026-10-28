module main

import vmem

// cmd_write performs a typed write: vmem write <pid> <addr> <type> <value>.
fn cmd_write(args []string) int {
	pos := positionals(args)
	if pos.len < 4 {
		eprintln('usage: vmem write <pid> <addr> <type> <value>')
		return 1
	}
	pid := pos[0].int()
	addr := parse_addr(pos[1]) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	kind := parse_kind(pos[2]) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	val := parse_num(pos[3]) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	n := write_kind(pid, addr, kind, val) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	println('wrote ${n} bytes')
	return 0
}

// write_kind encodes and writes one value of the given kind (CLI helper).
fn write_kind(pid int, addr u64, kind vmem.ValueKind, val f64) !int {
	match kind {
		.byte { return vmem.write_u8(pid, addr, u8(i64(val)))! }
		.word { return vmem.write_u16(pid, addr, u16(i64(val)))! }
		.dword { return vmem.write_u32(pid, addr, u32(i64(val)))! }
		.qword { return vmem.write_u64(pid, addr, u64(i64(val)))! }
		.float { return vmem.write_f32(pid, addr, f32(val))! }
		.double { return vmem.write_f64(pid, addr, val)! }
		else { return error('write type ${kind} unsupported; use AOB patch tooling') }
	}
}
