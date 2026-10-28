module main

import os

// vmem-radar — the Radar GUI front end (docs/GUI.md).
//
//   v run gui                    normal interactive session
//   v run gui -- --smoke 90      render 90 frames and exit (headless check)
fn main() {
	mut smoke := 0
	mut pid := 0
	mut value := ''
	args := os.args
	for i, a in args {
		if a == '--smoke' && i + 1 < args.len {
			smoke = args[i + 1].int()
		}
		if a == '--pid' && i + 1 < args.len {
			pid = args[i + 1].int()
		}
		if a == '--value' && i + 1 < args.len {
			value = args[i + 1]
		}
	}
	mut app := new_app(smoke)
	// demo mode: attach + scan immediately so the radar is alive on open
	if pid > 0 {
		app.value_str = pid.str()
		app.do_attach()
		if value != '' {
			app.value_str = value
			app.do_scan()
		}
	}
	app.run()
}
