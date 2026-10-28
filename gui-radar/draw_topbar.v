module main

import gg

// draw_topbar renders the target chip, region filter chips and live stats.
fn draw_topbar(mut ctx gg.Context, app &App) {
	ctx.draw_rect_filled(0, 0, 1280, 52, surface)
	ctx.draw_line(0, 52, 1280, 52, border)
	// target chip with icon
	tc := if app.attached { accent } else { muted }
	draw_icon(mut ctx, icon_target, 100, 26, 10, tc)
	if app.attached {
		ctx.draw_rect_filled(120, 12, 220, 28, surface_hi)
		ctx.draw_rect_empty(120, 12, 220, 28, accent)
		ctx.draw_text(134, 32, 'pid ${app.pid}  •  attached', gg.TextCfg{
			color: accent
			size:  15
		})
	} else {
		ctx.draw_rect_empty(120, 12, 220, 28, border)
		ctx.draw_text(134, 32, 'NO TARGET — press T', gg.TextCfg{
			color: muted
			size:  15
		})
	}
	// region filter chips
	chips := ['HEAP', 'CODE', 'STACK', 'ANON']
	for i, c in chips {
		x := 380 + i * 92
		ctx.draw_rect_empty(x, 13, 84, 26, border)
		ctx.draw_text(int(x + 42 - c.len * 4), 32, c, gg.TextCfg{
			color: muted
			size:  13
			align: .left
		})
	}
	// live stats
	ctx.draw_text(1120, 32, 'HITS', gg.TextCfg{ color: muted, size: 12 })
	ctx.draw_text(1180, 34, '${app.rows.len}', gg.TextCfg{
		color: if app.rows.len > 0 { accent } else { fg }
		size:  18
	})
	ctx.draw_text(1250, 32, 'v0.1', gg.TextCfg{ color: muted, size: 12 })
}
