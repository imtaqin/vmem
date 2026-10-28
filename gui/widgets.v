module main

import ui

// Widget helpers (one concern).

// dropdown_items converts names to dropdown rows.
fn dropdown_items(names []string) []ui.DropdownItem {
	mut out := []ui.DropdownItem{}
	for n in names {
		out << ui.DropdownItem{
			text: n
		}
	}
	return out
}

// proc_labels renders the process list for the dropdown.
fn (app &App) proc_labels() []string {
	mut out := []string{}
	for p in app.procs {
		out << '${p.pid}   ${p.name}'
	}
	return out
}
