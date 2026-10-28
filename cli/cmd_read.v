module main

import vmem

// cmd_read performs a typed read: vmem read <pid> <addr> <type> [--json].
fn cmd_read(args []string) int {
	pos := positionals(args)
	if pos.len < 3 {
		eprintln('usage: vmem read <pid> <addr> <type> [--json]')
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
	v := read_kind(pid, addr, kind) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	println(v)
	return 0
}

// read_kind decodes one value of the given kind at addr (CLI helper).
fn read_kind(pid int, addr u64, kind vmem.ValueKind) !string {
	match kind {
		.byte {
			v := vmem.read_u8(pid, addr)!
			return '${v}'
		}
		.word {
			v := vmem.read_u16(pid, addr)!
			return '${v}'
		}
		.dword {
			v := vmem.read_u32(pid, addr)!
			return '${v}'
		}
		.qword {
			v := vmem.read_u64(pid, addr)!
			return '${v}'
		}
		.float {
			v := vmem.read_f32(pid, addr)!
			return '${v}'
		}
		.double {
			v := vmem.read_f64(pid, addr)!
			return '${v}'
		}
		else {
			return error('read type ${kind} needs --len for raw bytes (dump command)')
		}
	}
}
