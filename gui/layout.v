module main

import ui
import vmem

// run_app builds the Cheat Engine style window and starts the UI loop.
fn run_app() {
	mut app := &App{}
	app.refresh_procs()

	// ===== toolbar: process selection + global actions =====
	toolbar := ui.row(
		spacing:  6
		widths:   [70.0, 260.0, 80.0, ui.stretch, 100.0, 90.0, 110.0, 110.0]
		children: [
			ui.label(text: 'PROCESS'),
			ui.dropdown(
				id:                   'dd_process'
				selected_index:       -1
				items:                dropdown_items(app.proc_labels())
				on_selection_changed: app.on_process
			),
			ui.button(text: 'Refresh', on_click: app.btn_refresh_procs),
			ui.label(id: 'lbl_proc', text: 'no process selected'),
			ui.button(text: 'New Scan', on_click: app.btn_new_scan),
			ui.button(text: 'Undo', on_click: app.btn_undo),
			ui.button(text: 'Save Table', on_click: app.btn_save_table),
			ui.button(text: 'Load Table', on_click: app.btn_load_table),
		]
	)

	// ===== scan control panel =====
	scan_panel := ui.column(
		margin_:  6
		spacing:  6
		heights:  [28.0, 28.0, 28.0, ui.compact]
		children: [
			ui.row(
				spacing:  6
				widths:   [70.0, 150.0, 90.0, ui.stretch]
				children: [ui.label(text: 'Value'),
					ui.textbox(
						id:          'tb_value'
						text:        &app.value_str
						placeholder: 'scan value'
					),
					ui.checkbox(id: 'cb_hex', text: 'Hex', on_click: app.on_hex),
					ui.label(text: 'for between use:  100;200')]
			),
			ui.row(
				spacing:  6
				widths:   [70.0, 200.0, 130.0, 110.0, ui.stretch]
				children: [ui.label(text: 'Scan Type'),
					ui.dropdown(
						id:                   'dd_scan'
						selected_index:       0
						items:                dropdown_items(app.scan_types)
						on_selection_changed: app.on_scan_type
					),
					ui.dropdown(
						id:                   'dd_type'
						selected_index:       2
						items:                dropdown_items(app.val_types)
						on_selection_changed: app.on_val_type
					),
					ui.dropdown(
						id:                   'dd_align'
						selected_index:       0
						items:                dropdown_items(app.aligns)
						on_selection_changed: app.on_align
					),
					ui.label(text: 'align')]
			),
			ui.row(
				spacing:  6
				widths:   [110.0, 110.0, 110.0, 110.0, ui.stretch]
				children: [ui.button(text: 'First Scan', on_click: app.btn_first),
					ui.button(text: 'Next Scan', on_click: app.btn_next),
					ui.button(text: 'Refine', on_click: app.btn_refine),
					ui.button(text: 'Unknown', on_click: app.btn_unknown),
					ui.label(id: 'lbl_found', text: 'Found: 0')]
			),
			ui.row(
				spacing:  6
				widths:   [120.0, ui.stretch]
				children: [
					ui.checkbox(
						id:       'cb_freeze'
						text:     'Freeze loop 10Hz'
						on_click: app.on_freeze_loop
					),
					ui.label(id: 'lbl_status', text: 'select a process to start'),
				]
			),
		]
	)

	// ===== results (left) + address list (right) =====
	table_panel := ui.column(
		margin_:  6
		spacing:  4
		heights:  [22.0, ui.stretch]
		children: [
			ui.label(text: 'ADDRESS LIST  (freeze / save)'),
			ui.row(
				spacing:  6
				widths:   [ui.stretch, 430.0]
				children: [
					ui.listbox(
						id:        'lb_results'
						on_change: app.on_select_result
						selection: -1
					),
					ui.column(
						spacing:  4
						widths:   ui.stretch
						heights:  [22.0, ui.stretch, 30.0, ui.compact]
						children: [ui.label(id: 'lbl_prev', text: 'selected: none'),
							ui.listbox(
								id:        'lb_table'
								on_change: app.on_select_table
								selection: -1
							),
							ui.row(
								spacing:  4
								widths:   ui.stretch
								children: [
									ui.button(text: 'Add', on_click: app.btn_add),
									ui.button(text: 'Delete', on_click: app.btn_delete),
									ui.button(text: 'Freeze', on_click: app.btn_freeze),
									ui.button(text: 'Edit', on_click: app.btn_edit),
								]
							),
							ui.row(
								spacing:  6
								widths:   [
									50.0,
									150.0,
									130.0,
									ui.stretch,
								]
								children: [
									ui.label(text: 'Desc'),
									ui.textbox(
										id:   'tb_desc'
										text: &app.desc_str
									),
									ui.button(text: 'Set Value', on_click: app.btn_set_value),
									ui.label(text: 'row value applied'),
								]
							)]
					),
				]
			),
		]
	)

	// ===== hex view =====
	hex_panel := ui.column(
		margin_:  6
		spacing:  4
		heights:  [28.0, ui.stretch]
		children: [
			ui.row(
				spacing:  6
				widths:   [60.0, 160.0, 80.0, ui.stretch]
				children: [ui.label(text: 'Address'),
					ui.textbox(
						id:          'tb_hexaddr'
						text:        &app.hexaddr_str
						placeholder: 'hex address'
					),
					ui.button(text: 'Go', on_click: app.btn_hex_go),
					ui.label(text: 'hex view of 256 bytes at address')]
			),
			ui.textbox(
				id:        'tb_hex'
				read_only: true
				text:      &app.hex_view
			),
		]
	)

	app.window = ui.window(
		title:    'Vmem CE'
		width:    1280
		height:   860
		children: [
			ui.column(
				margin_:  6
				spacing:  6
				heights:  [36.0, 130.0, ui.stretch, 170.0, 22.0]
				children: [toolbar, scan_panel, table_panel, hex_panel,
					ui.label(id: 'lbl_bar', text: 'Vmem - memory tool for Windows')]
			),
		]
	)
	app.lbl_proc = app.window.get_or_panic[ui.Label]('lbl_proc')
	app.lbl_found = app.window.get_or_panic[ui.Label]('lbl_found')
	app.lbl_status = app.window.get_or_panic[ui.Label]('lbl_status')
	app.lbl_prev = app.window.get_or_panic[ui.Label]('lbl_prev')
	app.lb_results = app.window.get_or_panic[ui.ListBox]('lb_results')
	app.lb_table = app.window.get_or_panic[ui.ListBox]('lb_table')
	app.dd_process = app.window.get_or_panic[ui.Dropdown]('dd_process')
	app.cb_hex = app.window.get_or_panic[ui.CheckBox]('cb_hex')
	app.cb_freeze = app.window.get_or_panic[ui.CheckBox]('cb_freeze')
	app.tb_value = app.window.get_or_panic[ui.TextBox]('tb_value')
	// freeze ticker keeps table values frozen while the game runs
	spawn app.freeze_ticker()
	ui.run(app.window)
}
