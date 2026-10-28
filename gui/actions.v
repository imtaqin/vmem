module main

import ui
import vmem

// CE-style widget handlers (one concern: UI events -> engine).

fn (mut app App) refresh_procs() {
	app.procs = vmem.enumerate_processes() or { []vmem.ProcessInfo{} }
}

fn (mut app App) btn_refresh_procs(btn &ui.Button) {
	app.refresh_procs()
	app.lbl_status.text = 'process list re-read: ${app.procs.len} entries (restart window to re-list)'
}

fn (mut app App) on_process(dd &ui.Dropdown) {
	idx := dd.selected_index
	if idx < 0 || idx >= app.procs.len {
		return
	}
	pid := app.procs[idx].pid
	app.mu.lock()
	b := vmem.new_local_backend(pid) or {
		app.mu.unlock()
		app.lbl_status.text = 'attach failed (run as admin for protected games): ${err.msg()}'
		return
	}
	app.b = b
	app.pid = pid
	app.attached = true
	app.mu.unlock()
	app.lbl_proc.text = 'pid ${pid}  ${app.procs[idx].name}'
	app.lbl_status.text = 'attached to ${app.procs[idx].name}'
}

fn (mut app App) on_hex(cb &ui.CheckBox) {
	app.hex_mode = cb.checked
}

fn (mut app App) on_scan_type(dd &ui.Dropdown) {
	app.lbl_status.text = 'scan type: ${app.scan_types[dd.selected_index]}'
}

fn (mut app App) on_val_type(dd &ui.Dropdown) {
	app.lbl_status.text = 'value type: ${app.val_types[dd.selected_index]}'
}

fn (mut app App) on_align(dd &ui.Dropdown) {
	app.lbl_status.text = 'alignment: ${app.aligns[dd.selected_index]}'
}

fn (mut app App) on_freeze_loop(cb &ui.CheckBox) {
	app.freeze_loop = cb.checked
	app.lbl_status.text = if cb.checked { 'freeze loop ON' } else { 'freeze loop off' }
}

// run_scan performs first/next/refine and refreshes the results table.
fn (mut app App) run_scan(mode string) {
	if !app.attached {
		app.lbl_status.text = 'select a process first'
		return
	}
	plan := app.cur_plan()
	app.mu.lock()
	mut n := 0
	if mode == 'first' {
		app.history << app.s
		if app.history.len > 10 {
			app.history = app.history[1..]
		}
		n = vmem.scan_first(mut app.b, mut app.s, plan) or {
			app.mu.unlock()
			app.lbl_status.text = 'scan error: ${err.msg()}'
			return
		}
	} else if mode == 'next' {
		app.history << app.s
		n = vmem.scan_next(mut app.b, mut app.s, plan) or {
			app.mu.unlock()
			app.lbl_status.text = 'scan error: ${err.msg()}'
			return
		}
	} else if mode == 'refine' {
		n = vmem.scan_refine(mut app.b, mut app.s, plan) or {
			app.mu.unlock()
			app.lbl_status.text = 'refine error: ${err.msg()}'
			return
		}
	} else {
		app.history << app.s
		n = vmem.scan_first(mut app.b, mut app.s, vmem.ScanPlan{
			kind: app.cur_kind()
			op:   .unknown
		}) or {
			app.mu.unlock()
			app.lbl_status.text = 'scan error: ${err.msg()}'
			return
		}
	}
	app.rows = vmem.get_results(&app.s, 0, 500)
	app.mu.unlock()
	app.reload_results()
	app.lbl_found.text = 'Found: ${vmem.result_count(&app.s)}'
	app.lbl_status.text = '${mode} scan done, ${n} kept'
}

fn (mut app App) reload_results() {
	app.lb_results.reset()
	for i, e in app.rows {
		app.lb_results.add_item('${i}', fmt_row(e))
	}
}

fn (mut app App) reload_table() {
	app.lb_table.reset()
	for i, t in app.table {
		app.lb_table.add_item('${i}', fmt_table_row(t))
	}
}

fn (mut app App) btn_first(btn &ui.Button) {
	app.run_scan('first')
}

fn (mut app App) btn_next(btn &ui.Button) {
	app.run_scan('next')
}

fn (mut app App) btn_refine(btn &ui.Button) {
	app.run_scan('refine')
}

fn (mut app App) btn_unknown(btn &ui.Button) {
	app.run_scan('unknown')
}

fn (mut app App) btn_new_scan(btn &ui.Button) {
	app.s = vmem.new_scan_session()
	app.history = []
	app.rows = []
	app.reload_results()
	app.lbl_found.text = 'Found: 0'
	app.lbl_status.text = 'new scan'
}

fn (mut app App) btn_undo(btn &ui.Button) {
	if app.history.len == 0 {
		app.lbl_status.text = 'nothing to undo'
		return
	}
	app.s = app.history[app.history.len - 1]
	app.history = app.history[..app.history.len - 1]
	app.rows = vmem.get_results(&app.s, 0, 500)
	app.reload_results()
	app.lbl_found.text = 'Found: ${vmem.result_count(&app.s)}'
	app.lbl_status.text = 'undo scan'
}

fn (mut app App) on_select_result(lb &ui.ListBox) {
	app.selected = lb.selection
	if app.selected < 0 || app.selected >= app.rows.len {
		app.lbl_prev.text = 'selected: none'
		return
	}
	e := app.rows[app.selected]
	app.lbl_prev.text = 'selected: 0x${e.address:x}  ${e.value}'
}

fn (mut app App) on_select_table(lb &ui.ListBox) {
	app.tselected = lb.selection
	if app.tselected < 0 || app.tselected >= app.table.len {
		return
	}
	t := app.table[app.tselected]
	app.lbl_prev.text = 'selected: 0x${t.addr:x}  ${t.desc}'
	app.desc_str = t.desc
}

// btn_add moves the selected scan hit to the address list.
fn (mut app App) btn_add(btn &ui.Button) {
	if app.selected < 0 || app.selected >= app.rows.len {
		app.lbl_status.text = 'select a scan result first'
		return
	}
	e := app.rows[app.selected]
	mut desc := app.desc_str
	if desc == '' {
		desc = 'entry ${app.table.len + 1}'
	}
	app.table << TableRow{
		desc:  desc
		addr:  e.address
		kind:  e.kind
		value: e.value
	}
	app.reload_table()
	app.lbl_status.text = 'added 0x${e.address:x} to address list'
}

fn (mut app App) btn_delete(btn &ui.Button) {
	if app.tselected < 0 || app.tselected >= app.table.len {
		app.lbl_status.text = 'select an address list row first'
		return
	}
	t := app.table[app.tselected]
	app.table.delete(app.tselected)
	app.reload_table()
	app.lbl_status.text = 'deleted 0x${t.addr:x}'
}

// btn_freeze toggles freezing for the selected address list row.
fn (mut app App) btn_freeze(btn &ui.Button) {
	if app.tselected < 0 || app.tselected >= app.table.len {
		app.lbl_status.text = 'select an address list row first'
		return
	}
	mut t := app.table[app.tselected]
	if t.frozen {
		t.frozen = false
		app.lbl_status.text = 'unfroze 0x${t.addr:x}'
	} else {
		app.mu.lock()
		vmem.freeze_add(mut app.f, t.addr, t.kind, t.value, 0, 0, .normal)
		vmem.freeze_tick(mut app.b, mut app.f) or {}
		app.mu.unlock()
		t.frozen = true
		app.lbl_status.text = 'froze 0x${t.addr:x}'
	}
	app.table[app.tselected] = t
	app.reload_table()
}

// btn_edit applies the Value field to the selected address list row.
fn (mut app App) btn_edit(btn &ui.Button) {
	if app.tselected < 0 || app.tselected >= app.table.len {
		app.lbl_status.text = 'select an address list row first'
		return
	}
	v1, _, _ := app.parse_value()
	mut t := app.table[app.tselected]
	app.mu.lock()
	vmem.edit_value(mut app.b, t.kind, t.addr, v1) or {
		app.mu.unlock()
		app.lbl_status.text = 'write failed: ${err.msg()}'
		return
	}
	app.mu.unlock()
	t.value = v1
	app.table[app.tselected] = t
	app.reload_table()
	app.lbl_status.text = 'wrote ${v1} to 0x${t.addr:x}'
}

// btn_set_value writes the Value field to every address list row.
fn (mut app App) btn_set_value(btn &ui.Button) {
	v1, _, _ := app.parse_value()
	mut count := 0
	for i in 0 .. app.table.len {
		app.mu.lock()
		vmem.edit_value(mut app.b, app.table[i].kind, app.table[i].addr, v1) or {
			app.mu.unlock()
			continue
		}
		app.mu.unlock()
		app.table[i].value = v1
		count++
	}
	app.reload_table()
	app.lbl_status.text = 'set ${count} entries to ${v1}'
}

// btn_save_table writes the address list to vmem_table.txt.
fn (mut app App) btn_save_table(btn &ui.Button) {
	mut entries := []vmem.TableEntry{}
	for t in app.table {
		entries << vmem.TableEntry{
			address: t.addr
			kind:    t.kind
			value:   t.value
			name:    t.desc
		}
	}
	vmem.save_list('vmem_table.txt', entries) or {
		app.lbl_status.text = 'save failed: ${err.msg()}'
		return
	}
	app.lbl_status.text = 'saved ${entries.len} entries to vmem_table.txt'
}

// btn_load_table reads vmem_table.txt into the address list.
fn (mut app App) btn_load_table(btn &ui.Button) {
	entries := vmem.load_list('vmem_table.txt') or {
		app.lbl_status.text = 'load failed: ${err.msg()}'
		return
	}
	app.table = []
	for e in entries {
		app.table << TableRow{
			desc:  e.name
			addr:  e.address
			kind:  e.kind
			value: e.value
		}
	}
	app.reload_table()
	app.lbl_status.text = 'loaded ${entries.len} entries from vmem_table.txt'
}

// btn_hex_go renders 256 bytes at the hex address field.
fn (mut app App) btn_hex_go(btn &ui.Button) {
	if !app.attached {
		app.lbl_status.text = 'select a process first'
		return
	}
	addr := hex_u64(app.hexaddr_str.trim_space().trim_left('0xX'))
	mut buf := []u8{len: 256}
	app.mu.lock()
	n := app.b.read_bytes(addr, mut buf) or {
		app.mu.unlock()
		app.lbl_status.text = 'hex read failed: ${err.msg()}'
		return
	}
	app.mu.unlock()
	app.hex_view = fmt_hexdump(addr, buf[..n])
	app.lbl_status.text = 'hex view at 0x${addr:x}'
}

// snapshot keeps address list values live.
fn (mut app App) btn_refresh_values(btn &ui.Button) {
	app.snapshot_table()
	app.reload_table()
}
