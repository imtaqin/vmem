module main

import ui
import sync
import vmem

// TableRow is one saved address-list entry (Cheat Engine table row).
pub struct TableRow {
pub mut:
	desc   string
	addr   u64
	kind   vmem.ValueKind
	value  f64
	frozen bool
}

// App is the Cheat Engine style front end. Windows first.
// All state changes go through mu because the freeze ticker runs in a
// background thread against the same backend.
@[heap]
struct App {
mut:
	window      &ui.Window   = unsafe { nil }
	dd_process  &ui.Dropdown = unsafe { nil }
	dd_scan     &ui.Dropdown = unsafe { nil }
	dd_type     &ui.Dropdown = unsafe { nil }
	dd_align    &ui.Dropdown = unsafe { nil }
	tb_value    &ui.TextBox  = unsafe { nil }
	tb_hexaddr  &ui.TextBox  = unsafe { nil }
	tb_desc     &ui.TextBox  = unsafe { nil }
	lb_results  &ui.ListBox  = unsafe { nil }
	lb_table    &ui.ListBox  = unsafe { nil }
	lbl_found   &ui.Label    = unsafe { nil }
	lbl_proc    &ui.Label    = unsafe { nil }
	lbl_status  &ui.Label    = unsafe { nil }
	lbl_prev    &ui.Label    = unsafe { nil }
	cb_hex      &ui.CheckBox = unsafe { nil }
	cb_freeze   &ui.CheckBox = unsafe { nil }
	mu          sync.Mutex
	value_str   string
	desc_str    string
	hexaddr_str string
	hex_view    string
	pid         int
	attached    bool
	b           vmem.LocalBackend
	s           vmem.ScanSession
	history     []vmem.ScanSession
	f           vmem.FreezeList
	rows        []vmem.ResultEntry
	table       []TableRow
	selected    int
	tselected   int
	procs       []vmem.ProcessInfo
	scan_types  []string = ['Exact Value', 'Bigger than...', 'Smaller than...', 'Value between...',
		'Unknown initial value', 'Increased value', 'Decreased value', 'Changed value',
		'Unchanged value']
	val_types   []string = ['Byte', '2 Bytes', '4 Bytes', '8 Bytes', 'Float', 'Double', 'Text',
		'Array of byte']
	aligns      []string = ['All', '2', '4', '8']
	hex_mode    bool
	freeze_loop bool
}
