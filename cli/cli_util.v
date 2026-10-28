module main

import vmem
import strconv

// Shared CLI parsing helpers (one concern: arg/number parsing).

fn parse_addr(s string) !u64 {
	t := s.trim_space().trim_left('0xX')
	if t.len == 0 {
		return error('bad address "${s}"')
	}
	return strconv.parse_uint(t, 16, 64) or { error('bad address "${s}"') }
}

fn parse_num(s string) !f64 {
	return s.f64()
}

fn parse_kind(s string) !vmem.ValueKind {
	return vmem.kind_from_name(s) or { error('bad type "${s}"') }
}

fn parse_op(s string) !vmem.CompareOp {
	return match s {
		'eq' { vmem.CompareOp.eq }
		'ne' { vmem.CompareOp.ne }
		'gt' { vmem.CompareOp.gt }
		'ge' { vmem.CompareOp.ge }
		'lt' { vmem.CompareOp.lt }
		'le' { vmem.CompareOp.le }
		'between' { vmem.CompareOp.between }
		'changed' { vmem.CompareOp.changed }
		'unchanged' { vmem.CompareOp.unchanged }
		'increased' { vmem.CompareOp.increased }
		'increased_by' { vmem.CompareOp.increased_by }
		'decreased' { vmem.CompareOp.decreased }
		'decreased_by' { vmem.CompareOp.decreased_by }
		'same_as_first' { vmem.CompareOp.same_as_first }
		'unknown' { vmem.CompareOp.unknown }
		else { error('bad op "${s}"') }
	}
}

fn has_flag(args []string, name string) bool {
	return name in args
}

fn flag_val(args []string, name string) string {
	for i, a in args {
		if a == name && i + 1 < args.len {
			return args[i + 1]
		}
	}
	return ''
}

fn positionals(args []string) []string {
	mut out := []string{}
	mut skip := false
	for a in args {
		if skip {
			skip = false
			continue
		}
		if a.starts_with('--') {
			// flags taking values: --state --type --op --value --value2 --limit
			// --depth --offset --align --class --aob --text --mode
			if a in ['--state', '--type', '--op', '--value', '--value2', '--limit', '--depth',
				'--offset', '--align', '--class', '--aob', '--text', '--mode', '--kind'] {
				skip = true
			}
			continue
		}
		out << a
	}
	return out
}
