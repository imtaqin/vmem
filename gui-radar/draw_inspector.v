module main

import gg

// draw_inspector renders the right-column inspector: selected result detail
// with raw hex bytes and quick actions.
fn draw_inspector(mut ctx gg.Context, app &App) {
	ctx.draw_rect_filled(920, 556, 360, 224, surface)
	ctx.draw_line(920, 556, 920, 780, border)
	ctx.draw_text(944, 586, 'INSPECTOR', gg.TextCfg{ color: muted, size: 13 })
	ctx.draw_line(944, 596, 1256, 596, border)
	if app.rows.len == 0 || app.selected >= app.rows.len {
		draw_icon(mut ctx, icon_ptr, 1100, 680, 22, border)
		ctx.draw_text(1024, 728, 'select a result', gg.TextCfg{ color: muted, size: 14 })
		return
	}
	e := app.rows[app.selected]
	ctx.draw_text(944, 626, 'address', gg.TextCfg{ color: muted, size: 11 })
	ctx.draw_text(1024, 628, '0x${e.address:x}', gg.TextCfg{ color: fg, size: 15 })
	ctx.draw_text(944, 654, 'value', gg.TextCfg{ color: muted, size: 11 })
	ctx.draw_text(1024, 656, fmt_val(e.kind, e.value), gg.TextCfg{ color: accent, size: 17 })
	ctx.draw_text(944, 682, 'kind', gg.TextCfg{ color: muted, size: 11 })
	ctx.draw_text(1024, 684, '${e.kind}', gg.TextCfg{ color: fg, size: 14 })
	ctx.draw_text(944, 710, 'stable', gg.TextCfg{ color: muted, size: 11 })
	ctx.draw_text(1024, 712, '${e.stable} passes', gg.TextCfg{ color: fg, size: 14 })
	// raw hex
	mut hex := ''
	for b in e.raw {
		hex += '${b:02x} '
	}
	ctx.draw_text(944, 742, 'raw', gg.TextCfg{ color: muted, size: 11 })
	ctx.draw_text(990, 744, hex, gg.TextCfg{ color: success, size: 13 })
	// quick actions
	ctx.draw_rect_empty(944, 754, 100, 22, accent)
	ctx.draw_text(994, 770, 'FREEZE', gg.TextCfg{ color: accent, size: 12, align: .center })
	ctx.draw_rect_empty(1056, 754, 100, 22, border)
	ctx.draw_text(1106, 770, 'DUMP', gg.TextCfg{ color: muted, size: 12, align: .center })
	ctx.draw_rect_empty(1168, 754, 88, 22, border)
	ctx.draw_text(1212, 770, 'COPY', gg.TextCfg{ color: muted, size: 12, align: .center })
}
