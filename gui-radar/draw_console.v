module main

import gg

// draw_console renders the compact scan console: big input fields in one
// row, a solid SCAN action, and mode tabs.
fn draw_console(mut ctx gg.Context, app &App) {
	ctx.draw_rect_filled(76, 52, 1204, 84, surface)
	ctx.draw_line(76, 136, 1280, 136, border)
	// value input (big)
	vc := if app.field == 0 { accent } else { border }
	ctx.draw_rect_filled(100, 68, 300, 48, surface_hi)
	ctx.draw_rect_empty(100, 68, 300, 48, vc)
	ctx.draw_text(116, 86, 'VALUE', gg.TextCfg{ color: muted, size: 11 })
	vtxt := if app.value_str == '' { 'type here…' } else { app.value_str }
	ctx.draw_text(116, 108, vtxt, gg.TextCfg{
		color: if app.value_str == '' { muted } else { fg }
		size:  18
	})
	// type + op pickers
	tc := if app.field == 1 { accent } else { border }
	ctx.draw_rect_filled(416, 68, 170, 48, surface_hi)
	ctx.draw_rect_empty(416, 68, 170, 48, tc)
	ctx.draw_text(432, 86, 'TYPE', gg.TextCfg{ color: muted, size: 11 })
	ctx.draw_text(432, 108, '${app.kind}', gg.TextCfg{ color: fg, size: 17 })
	oc := if app.field == 2 { accent } else { border }
	ctx.draw_rect_filled(602, 68, 210, 48, surface_hi)
	ctx.draw_rect_empty(602, 68, 210, 48, oc)
	ctx.draw_text(618, 86, 'COMPARE', gg.TextCfg{ color: muted, size: 11 })
	ctx.draw_text(618, 108, '${app.op}', gg.TextCfg{ color: fg, size: 17 })
	// SCAN button
	ctx.draw_rect_filled(838, 68, 170, 48, accent)
	ctx.draw_text(906, 100, 'SCAN (ENTER)', gg.TextCfg{
		color: bg
		size:  19
		align: .center
	})
	// mode tabs
	modes := ['FIRST', 'NEXT', 'REFINE']
	for i, m in modes {
		x := 1040 + f32(i) * 76
		is_first := i == 0
		ctx.draw_rect_empty(x, 68, 70, 22, if is_first { accent } else { border })
		ctx.draw_text(int(x + 35), 84, m, gg.TextCfg{
			color: if is_first { accent } else { muted }
			size:  11
			align: .center
		})
	}
	ctx.draw_text(1040, 112, 'Tab: field   T: attach', gg.TextCfg{ color: muted, size: 12 })
}
