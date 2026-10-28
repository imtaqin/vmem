module main

import gg
import vmem

// App is the Radar GUI state (docs/GUI.md). It drives the vmem public API
// only (AGENTS.md §2).
pub struct App {
mut:
	gg        &gg.Context = unsafe { nil }
	pid       int
	attached  bool
	b         vmem.LocalBackend
	s         vmem.ScanSession
	f         vmem.FreezeList
	regions   []vmem.Region
	rows      []vmem.ResultEntry
	hist      map[u64][]f64
	field     int // 0=value 1=type 2=op
	value_str string
	kind      vmem.ValueKind = .dword
	op        vmem.CompareOp = .eq
	selected  int
	status    string = 'ready — Ctrl+K for commands'
	palette   bool
	frames    int
	smoke     int
	frozen    map[u64]bool
}

// new_app builds the app; smoke>0 renders that many frames and quits
// (headless verification path).
pub fn new_app(smoke int) &App {
	mut app := &App{
		smoke: smoke
	}
	app.gg = gg.new_context(
		width:        1280
		height:       860
		window_title: 'Vmem — Radar'
		bg_color:     bg
		frame_fn:     frame
		char_fn:      on_char
		keydown_fn:   on_key
		user_data:    app
	)
	app.s = vmem.new_scan_session()
	return app
}

// run starts the event loop.
pub fn (mut app App) run() {
	app.gg.run()
}

// tick pulls engine snapshots into the view models (bounded work).
fn (mut app App) tick() {
	if !app.attached {
		return
	}
	app.rows = vmem.get_results(&app.s, 0, 400)
	for e in app.rows {
		mut h := app.hist[e.address]
		h << e.value
		if h.len > 48 {
			h = h[1..]
		}
		app.hist[e.address] = h
	}
}

fn frame(data voidptr) {
	mut app := unsafe { &App(data) }
	mut ctx := app.gg
	app.frames++
	if app.frames % 30 == 0 {
		app.tick()
	}
	ctx.begin()
	draw_topbar(mut ctx, app)
	draw_rail(mut ctx, app)
	draw_console(mut ctx, app)
	draw_table(mut ctx, app)
	draw_donut(mut ctx, app)
	draw_inspector(mut ctx, app)
	draw_timeline(mut ctx, app)
	draw_status(mut ctx, app)
	if app.palette {
		draw_palette(mut ctx, app)
	}
	ctx.end()
	if app.smoke > 0 && app.frames >= app.smoke {
		exit(0)
	}
	_ := gg.Color{}
}
