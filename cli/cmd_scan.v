module main

import vmem

// cmd_scan runs scan passes with a state file between invocations:
//
//   vmem scan first  --pid N --state F --op eq --type dword --value 100
//   vmem scan next   --state F --op increased
//   vmem scan refine --state F --op lt --value 50
//
// Flags: --value2 (between), --align, --limit, --aob "48 8B ??", --text "s"
// [--kind text], --start/--end address range.
fn cmd_scan(args []string) int {
	pos := positionals(args)
	if pos.len < 1 {
		eprintln('usage: vmem scan <first|next|refine> --state F [--pid N] ...')
		return 1
	}
	mode := pos[0]
	state := flag_val(args, '--state')
	if state == '' {
		eprintln('error: --state <file> required')
		return 1
	}
	mut plan := build_plan(args) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	mut count := 0
	match mode {
		'first' {
			pid := flag_val(args, '--pid').int()
			mut b := vmem.new_local_backend(pid) or {
				eprintln('error: ${err.msg()}')
				return 1
			}
			defer {
				b.detach() or {}
			}
			mut s := vmem.new_scan_session()
			count = vmem.scan_first(mut b, mut s, plan) or {
				eprintln('error: ${err.msg()}')
				return 1
			}
			vmem.save_session(&s, state) or {
				eprintln('error: ${err.msg()}')
				return 1
			}
		}
		'next', 'refine' {
			pid := flag_val(args, '--pid').int()
			if pid == 0 {
				eprintln('error: --pid N required')
				return 1
			}
			mut b := vmem.new_local_backend(pid) or {
				eprintln('error: ${err.msg()}')
				return 1
			}
			defer {
				b.detach() or {}
			}
			mut s := vmem.load_session(state) or {
				eprintln('error: ${err.msg()}')
				return 1
			}
			count = if mode == 'next' {
				vmem.scan_next(mut b, mut s, plan) or {
					eprintln('error: ${err.msg()}')
					return 1
				}
			} else {
				vmem.scan_refine(mut b, mut s, plan) or {
					eprintln('error: ${err.msg()}')
					return 1
				}
			}
			vmem.save_session(&s, state) or {
				eprintln('error: ${err.msg()}')
				return 1
			}
		}
		else {
			eprintln('usage: vmem scan <first|next|refine> ...')
			return 1
		}
	}

	println('hits: ${count}')
	return 0
}

// build_plan assembles a ScanPlan from CLI flags.
fn build_plan(args []string) !vmem.ScanPlan {
	mut kind := vmem.ValueKind.dword
	mut op := vmem.CompareOp.eq
	mut value := f64(0)
	mut value2 := f64(0)
	mut pattern := vmem.ScanPattern{}
	t := flag_val(args, '--type')
	if t != '' {
		kind = parse_kind(t)!
	}
	o := flag_val(args, '--op')
	if o != '' {
		op = parse_op(o)!
	}
	v := flag_val(args, '--value')
	if v != '' {
		value = parse_num(v)!
	}
	v2 := flag_val(args, '--value2')
	if v2 != '' {
		value2 = parse_num(v2)!
	}
	a := flag_val(args, '--aob')
	if a != '' {
		kind = .aob
		pattern = vmem.parse_aob(a)!
	}
	txt := flag_val(args, '--text')
	if txt != '' {
		kind = .text
		pattern = vmem.pattern_from_text(txt, .utf8)!
	}
	mut filter := vmem.ScanFilter{}
	st := flag_val(args, '--start')
	if st != '' {
		filter = vmem.ScanFilter{
			start: parse_addr(st)!
			end:   filter.end
		}
	}
	en := flag_val(args, '--end')
	if en != '' {
		filter = vmem.ScanFilter{
			start: filter.start
			end:   parse_addr(en)!
		}
	}
	align := flag_val(args, '--align').u64()
	limit := flag_val(args, '--limit').int()
	return vmem.ScanPlan{
		kind:    kind
		op:      op
		value:   value
		value2:  value2
		align:   if align == 0 { u64(1) } else { align }
		limit:   limit
		filter:  filter
		pattern: pattern
	}
}
