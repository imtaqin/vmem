module main

import gg

// draw_rail renders the left icon rail: icon buttons with labels,
// active item gets an accent pill (docs/GUI.md §3).
fn draw_rail(mut ctx gg.Context, app &App) {
	ctx.draw_rect_filled(0, 0, 76, 860, surface)
	ctx.draw_line(76, 0, 76, 860, border)
	items := [icon_proc, icon_scan, icon_ptr, icon_code, icon_dbg]
	labels := ['PROC', 'SCAN', 'PTR', 'CODE', 'DBG']
	for i, kind in items {
		y := 120 + i * 84
		active := i == 1
		if active {
			ctx.draw_rect_filled(12, y - 30, 52, 60, surface_hi)
			ctx.draw_rect_filled(12, y - 30, 3, 60, accent)
		}
		c := if active { accent } else { muted }
		draw_icon(mut ctx, kind, 38, y - 8, 12, c)
		ctx.draw_text(38 - labels[i].len * 3, int(y + 24), labels[i], gg.TextCfg{
			color: c
			size:  11
		})
	}
	// footer icon: freeze status
	draw_icon(mut ctx, icon_freeze, 38, 800, 11, if app.frozen.len > 0 { warning } else { muted })
}
