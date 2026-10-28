module main

import gg

// draw_table renders the virtualized results table: zebra rows, big values,
// delta badges and per-row sparklines (docs/GUI.md — unique to Radar).
fn draw_table(mut ctx gg.Context, app &App) {
	top := f32(136)
	ctx.draw_rect_filled(76, top, 844, 644, surface)
	// column header
	ctx.draw_rect_filled(76, top, 844, 34, surface_hi)
	ctx.draw_text(100, int(top + 23), 'ADDRESS', gg.TextCfg{ color: muted, size: 12 })
	ctx.draw_text(330, int(top + 23), 'VALUE', gg.TextCfg{ color: muted, size: 12 })
	ctx.draw_text(520, int(top + 23), 'DELTA', gg.TextCfg{ color: muted, size: 12 })
	ctx.draw_text(660, int(top + 23), 'HISTORY', gg.TextCfg{ color: muted, size: 12 })
	ctx.draw_text(830, int(top + 23), 'FRZ', gg.TextCfg{ color: muted, size: 12 })
	ctx.draw_line(76, top + 34, 920, top + 34, border)
	if app.rows.len == 0 {
		draw_icon(mut ctx, icon_scan, 498, top + 280, 34, border)
		ctx.draw_text(420, int(top + 350), 'no results yet', gg.TextCfg{ color: muted, size: 17 })
		ctx.draw_text(356, int(top + 378), 'attach (T), type a value, hit SCAN', gg.TextCfg{
			color: muted
			size:  13
		})
		return
	}
	mut shown := 0
	for i, e in app.rows {
		if shown >= 24 {
			break
		}
		y := top + 62 + f32(i) * 25
		if i == app.selected {
			ctx.draw_rect_filled(84, y - 17, 828, 23, surface_hi)
			ctx.draw_rect_filled(84, y - 17, 3, 23, accent)
		} else if i % 2 == 0 {
			ctx.draw_rect_filled(84, y - 17, 828, 23, bg)
		}
		ctx.draw_text(100, int(y), '0x${e.address:x}', gg.TextCfg{ color: fg, size: 14 })
		ctx.draw_text(330, int(y), fmt_val(e.kind, e.value), gg.TextCfg{ color: accent, size: 15 })
		d := e.value - e.prev
		dc := if d > 0 {
			success
		} else {
			if d < 0 { errc } else { muted }
		}
		if d != 0 {
			ctx.draw_rect_filled(520, y - 13, 66, 18, surface_hi)
		}
		ctx.draw_text(528, int(y), fmt_delta(e.kind, d), gg.TextCfg{ color: dc, size: 13 })
		// sparkline
		h := app.hist[e.address]
		if h.len > 1 {
			mut lo := h[0]
			mut hi := h[0]
			for v in h {
				if v < lo {
					lo = v
				}
				if v > hi {
					hi = v
				}
			}
			rng := if hi - lo < 0.0001 { f64(1) } else { hi - lo }
			ctx.draw_line(660, y - 8, 796, y - 8, border)
			for j in 1 .. h.len {
				x0 := 660 + f32(j - 1) * 2.9
				x1 := 660 + f32(j) * 2.9
				y0 := y - 8 - f32((h[j - 1] - lo) / rng * 14.0)
				y1 := y - 8 - f32((h[j] - lo) / rng * 14.0)
				ctx.draw_line(x0, y0, x1, y1, c1)
			}
		}
		if app.frozen[e.address] {
			draw_icon(mut ctx, icon_freeze, 846, y - 5, 8, warning)
		} else {
			ctx.draw_text(842, int(y), '–', gg.TextCfg{ color: border, size: 14 })
		}
		shown++
	}
}
