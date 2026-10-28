module main

import gg
import vmem

// Keyboard and text input handling for the Radar GUI (docs/GUI.md §5).

fn on_char(c u32, data voidptr) {
	mut app := unsafe { &App(data) }
	if app.palette {
		return
	}
	if app.field == 0 && c >= 32 && c < 127 {
		app.value_str += rune(c).str()
	}
}

fn on_key(c gg.KeyCode, m gg.Modifier, data voidptr) {
	mut app := unsafe { &App(data) }
	match c {
		.escape {
			app.palette = false
		}
		.tab {
			app.field = (app.field + 1) % 3
		}
		.backspace {
			if app.field == 0 && app.value_str.len > 0 {
				app.value_str = app.value_str[..app.value_str.len - 1]
			}
		}
		.up {
			if app.selected > 0 {
				app.selected--
			}
		}
		.down {
			if app.selected + 1 < app.rows.len {
				app.selected++
			}
		}
		.enter {
			app.do_scan()
		}
		.space {
			app.do_freeze_toggle()
		}
		.t {
			app.do_attach()
		}
		.r {
			app.do_refresh()
		}
		.d {
			app.do_dump()
		}
		.k {
			if m == .ctrl || m == .super {
				app.palette = !app.palette
			}
		}
		else {}
	}
}

// do_attach attaches to the pid typed in the value field.
fn (mut app App) do_attach() {
	pid := app.value_str.int()
	if pid <= 0 {
		app.status = 'attach: type a pid in the value field first'
		return
	}
	b := vmem.new_local_backend(pid) or {
		app.status = 'attach failed: ${err.msg()}'
		return
	}
	app.b = b
	app.pid = pid
	app.attached = true
	app.value_str = ''
	app.do_refresh()
	app.status = 'attached to pid ${pid}'
}

// do_refresh reloads regions and results snapshots.
fn (mut app App) do_refresh() {
	if !app.attached {
		return
	}
	app.regions = app.b.enumerate_regions() or { []vmem.Region{} }
	app.tick()
	app.status = 'refreshed: ${app.regions.len} regions, ${app.rows.len} rows'
}

// do_scan runs the scan for the current field values.
fn (mut app App) do_scan() {
	if !app.attached {
		app.status = 'scan: attach first (T)'
		return
	}
	mut plan := vmem.ScanPlan{
		kind: app.kind
		op:   app.op
	}
	if app.value_str != '' {
		plan = vmem.ScanPlan{
			kind:  app.kind
			op:    app.op
			value: app.value_str.f64()
		}
	}
	n := if app.s.scans == 0 {
		vmem.scan_first(mut app.b, mut app.s, plan) or {
			app.status = 'scan error: ${err.msg()}'
			return
		}
	} else {
		vmem.scan_next(mut app.b, mut app.s, plan) or {
			app.status = 'scan error: ${err.msg()}'
			return
		}
	}
	app.selected = 0
	app.status = 'scan done: ${n} hits'
}

// do_freeze_toggle freezes or unfreezes the selected row.
fn (mut app App) do_freeze_toggle() {
	if !app.attached || app.selected >= app.rows.len {
		return
	}
	e := app.rows[app.selected]
	if app.frozen[e.address] {
		app.frozen[e.address] = false
		app.status = 'unfroze 0x${e.address:x}'
		return
	}
	vmem.freeze_add(mut app.f, e.address, e.kind, e.value, 0, 0, .normal)
	vmem.freeze_tick(mut app.b, mut app.f) or {}
	app.frozen[e.address] = true
	app.status = 'froze 0x${e.address:x} = ${e.value}'
}

// do_dump dumps the selected row's region to radar_dump.bin.
fn (mut app App) do_dump() {
	if !app.attached {
		return
	}
	if app.selected >= app.rows.len {
		app.status = 'dump: no selection'
		return
	}
	e := app.rows[app.selected]
	vmem.dump_memory(mut app.b, 'radar_dump.bin', e.address, e.address + 0x1000) or {
		app.status = 'dump failed: ${err.msg()}'
		return
	}
	app.status = 'dumped 4K at 0x${e.address:x} to radar_dump.bin'
}
