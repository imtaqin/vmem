module main

import gg

// draw_status renders the bottom status bar and the command palette.
fn draw_status(mut ctx gg.Context, app &App) {
	ctx.draw_rect_filled(0, 830, 1280, 30, surface_hi)
	ctx.draw_line(0, 830, 1280, 830, border)
	draw_icon(mut ctx, icon_scan, 24, 845, 8, accent)
	ctx.draw_text(42, 850, app.status, gg.TextCfg{ color: fg, size: 13 })
	ctx.draw_text(1120, 850, 'Ctrl+K commands', gg.TextCfg{ color: muted, size: 12 })
}

// draw_palette renders the command palette overlay (Ctrl+K).
fn draw_palette(mut ctx gg.Context, app &App) {
	ctx.draw_rect_filled(340, 180, 600, 360, surface)
	ctx.draw_rect_empty(340, 180, 600, 360, accent)
	ctx.draw_rect_filled(340, 180, 600, 48, surface_hi)
	ctx.draw_text(372, 212, 'COMMANDS', gg.TextCfg{ color: fg, size: 18 })
	ctx.draw_text(860, 212, 'esc to close', gg.TextCfg{ color: muted, size: 12 })
	entries := [
		['T', 'attach to the pid typed in VALUE'],
		['⏎', 'run scan (FIRST / NEXT / REFINE tab)'],
		['↑ ↓', 'select result row'],
		['Space', 'freeze / unfreeze selection'],
		['R', 'refresh regions + results'],
		['D', 'dump selection page to radar_dump.bin'],
		['Tab', 'cycle VALUE / TYPE / COMPARE fields'],
	]
	for i, e in entries {
		y := 268 + i * 38
		ctx.draw_rect_filled(372, y - 20, 56, 26, surface_hi)
		ctx.draw_text(400, int(y), e[0], gg.TextCfg{ color: accent, size: 14, align: .center })
		ctx.draw_text(448, int(y), e[1], gg.TextCfg{ color: fg, size: 14 })
	}
}
