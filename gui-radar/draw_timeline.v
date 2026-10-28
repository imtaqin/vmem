module main

import gg

// draw_timeline renders the scan-state timeline (one node per pass).
fn draw_timeline(mut ctx gg.Context, app &App) {
	top := f32(780)
	ctx.draw_rect_filled(76, top, 1204, 50, surface)
	ctx.draw_line(76, top, 1280, top, border)
	ctx.draw_text(100, int(top + 31), 'SCAN TIMELINE', gg.TextCfg{ color: muted, size: 12 })
	ctx.draw_line(260, top + 25, 1120, top + 25, border)
	passes := if app.s.scans > 8 { 8 } else { app.s.scans }
	for i in 0 .. passes {
		x := 320 + f32(i) * 100
		last := i == passes - 1
		c := if last { accent } else { muted }
		if last {
			ctx.draw_circle_filled(x, top + 25, 7, c)
			ctx.draw_circle_empty(x, top + 25, 12, c)
		} else {
			ctx.draw_circle_filled(x, top + 25, 5, c)
		}
		label := if i == 0 { 'first' } else { 'pass ${i + 1}' }
		ctx.draw_text(int(x - 18), int(top + 46), label, gg.TextCfg{ color: c, size: 11 })
	}
	ctx.draw_text(1140, int(top + 30), 'Ctrl+Z back', gg.TextCfg{ color: muted, size: 12 })
}
