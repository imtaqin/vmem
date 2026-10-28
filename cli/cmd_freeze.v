module main

import vmem

// cmd_freeze freezes values while it runs:
//
//   vmem freeze --pid N --addr A --type T --value V [--mode normal|
//               may_increase|may_decrease|in_range] [--from X --to Y]
//               [--seconds S]   (S default 5, tick ~10 Hz)
fn cmd_freeze(args []string) int {
	pid := flag_val(args, '--pid').int()
	addr_s := flag_val(args, '--addr')
	if pid == 0 || addr_s == '' {
		eprintln('usage: vmem freeze --pid N --addr A --type T --value V [...]')
		return 1
	}
	addr := parse_addr(addr_s) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	kind := parse_kind(flag_val(args, '--type')) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	value := parse_num(flag_val(args, '--value')) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	mut from := f64(0)
	mut to := f64(0)
	fv := flag_val(args, '--from')
	if fv != '' {
		from = parse_num(fv) or { 0 }
	}
	tv := flag_val(args, '--to')
	if tv != '' {
		to = parse_num(tv) or { 0 }
	}
	mode := match flag_val(args, '--mode') {
		'may_increase' { vmem.FreezeMode.may_increase }
		'may_decrease' { vmem.FreezeMode.may_decrease }
		'in_range' { vmem.FreezeMode.in_range }
		else { vmem.FreezeMode.normal }
	}

	seconds := if flag_val(args, '--seconds') == '' { 5 } else { flag_val(args, '--seconds').int() }
	mut b := vmem.new_local_backend(pid) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	defer {
		b.detach() or {}
	}
	mut f := vmem.FreezeList{}
	vmem.freeze_add(mut f, addr, kind, value, from, to, mode)
	writes := vmem.freeze_run(mut b, mut f, seconds * 1000) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	println('freeze done: ${writes} writes over ${seconds}s')
	return 0
}
