module main

import vmem

// CE-style scan configuration mapping (one concern: UI state -> engine).

// cur_kind maps the Value Type dropdown to a vmem kind.
fn (app &App) cur_kind() vmem.ValueKind {
	idx := app.dd_type.selected_index
	return match idx {
		0 { vmem.ValueKind.byte }
		1 { vmem.ValueKind.word }
		2 { vmem.ValueKind.dword }
		3 { vmem.ValueKind.qword }
		4 { vmem.ValueKind.float }
		5 { vmem.ValueKind.double }
		6 { vmem.ValueKind.text }
		else { vmem.ValueKind.aob }
	}
}

// cur_op maps the Scan Type dropdown to a compare op.
fn (app &App) cur_op() vmem.CompareOp {
	idx := app.dd_scan.selected_index
	return match idx {
		1 { vmem.CompareOp.gt }
		2 { vmem.CompareOp.lt }
		3 { vmem.CompareOp.between }
		4 { vmem.CompareOp.unknown }
		5 { vmem.CompareOp.increased }
		6 { vmem.CompareOp.decreased }
		7 { vmem.CompareOp.changed }
		8 { vmem.CompareOp.unchanged }
		else { vmem.CompareOp.eq }
	}
}

// cur_align maps the alignment dropdown (All/2/4/8).
fn (app &App) cur_align() u64 {
	return match app.dd_align.selected_index {
		1 { u64(2) }
		2 { u64(4) }
		3 { u64(8) }
		else { u64(1) }
	}
}

// parse_value decodes the value field: decimal or hex (Hex checkbox),
// "a;b" for between scans. Text/AoB kinds use the raw field content.
fn (app &App) parse_value() (f64, f64, string) {
	raw := app.value_str.trim_space()
	mut v1 := f64(0)
	mut v2 := f64(0)
	if raw.contains(';') {
		parts := raw.split(';')
		v1 = app.num(parts[0])
		if parts.len > 1 {
			v2 = app.num(parts[1])
		}
	} else {
		v1 = app.num(raw)
	}
	return v1, v2, raw
}

// num parses one number honoring the Hex checkbox.
fn (app &App) num(s string) f64 {
	t := s.trim_space()
	if app.hex_mode {
		return f64(hex_u64(t.trim_left('0xX')))
	}
	return t.f64()
}

// hex_u64 parses a hex string (no prefix needed).
fn hex_u64(s string) u64 {
	mut v := u64(0)
	for i in 0 .. s.len {
		c := s[i]
		mut n := 0
		if c >= `0` && c <= `9` {
			n = int(c - `0`)
		} else if c >= `a` && c <= `f` {
			n = int(c - `a`) + 10
		} else if c >= `A` && c <= `F` {
			n = int(c - `A`) + 10
		} else {
			return v
		}
		v = v * 16 + u64(n)
	}
	return v
}

// cur_plan builds the engine plan from the current panel state.
fn (app &App) cur_plan() vmem.ScanPlan {
	v1, v2, raw := app.parse_value()
	mut pattern := vmem.ScanPattern{}
	kind := app.cur_kind()
	if kind == .text {
		pattern = vmem.pattern_from_text(raw, .utf8) or { vmem.ScanPattern{} }
	}
	if kind == .aob {
		pattern = vmem.parse_aob(raw) or { vmem.ScanPattern{} }
	}
	return vmem.ScanPlan{
		kind:    kind
		op:      app.cur_op()
		value:   v1
		value2:  v2
		align:   app.cur_align()
		pattern: pattern
	}
}
