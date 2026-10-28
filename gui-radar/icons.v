module main

import gg

// draw_icon renders small vector icons for the rail and panels
// (no font glyphs — pure geometry, theme-agnostic).

// icon kinds
const icon_proc = 0
const icon_scan = 1
const icon_ptr = 2
const icon_code = 3
const icon_dbg = 4
const icon_target = 5
const icon_freeze = 6
const icon_dump = 7

fn draw_icon(mut ctx gg.Context, kind int, cx f32, cy f32, s f32, c gg.Color) {
	match kind {
		icon_proc {
			// stacked layers
			ctx.draw_rect_empty(cx - s, cy - s * 0.7, s * 2, s * 0.9, c)
			ctx.draw_rect_empty(cx - s * 0.8, cy - s * 0.15, s * 1.6, s * 0.9, c)
		}
		icon_scan {
			// radar: ring + sweep
			ctx.draw_circle_empty(cx, cy, s, c)
			ctx.draw_circle_empty(cx, cy, s * 0.55, c)
			ctx.draw_line(cx, cy, cx + s * 0.85, cy - s * 0.85, c)
			ctx.draw_circle_filled(cx, cy, s * 0.12, c)
		}
		icon_ptr {
			// chain link
			ctx.draw_rect_empty(cx - s, cy - s * 0.35, s * 1.1, s * 0.7, c)
			ctx.draw_rect_empty(cx - s * 0.1, cy - s * 0.35, s * 1.1, s * 0.7, c)
		}
		icon_code {
			// angle brackets
			ctx.draw_line(cx - s * 0.25, cy - s, cx - s, cy, c)
			ctx.draw_line(cx - s, cy, cx - s * 0.25, cy + s, c)
			ctx.draw_line(cx + s * 0.25, cy - s, cx + s, cy, c)
			ctx.draw_line(cx + s, cy, cx + s * 0.25, cy + s, c)
		}
		icon_dbg {
			// bug: body + legs
			ctx.draw_circle_empty(cx, cy, s * 0.55, c)
			ctx.draw_line(cx - s, cy - s * 0.7, cx - s * 0.35, cy - s * 0.25, c)
			ctx.draw_line(cx + s, cy - s * 0.7, cx + s * 0.35, cy - s * 0.25, c)
			ctx.draw_line(cx - s, cy + s * 0.7, cx - s * 0.35, cy + s * 0.25, c)
			ctx.draw_line(cx + s, cy + s * 0.7, cx + s * 0.35, cy + s * 0.25, c)
		}
		icon_target {
			ctx.draw_circle_empty(cx, cy, s, c)
			ctx.draw_circle_filled(cx, cy, s * 0.35, c)
			ctx.draw_line(cx - s * 1.4, cy, cx - s * 1.1, cy, c)
			ctx.draw_line(cx + s * 1.1, cy, cx + s * 1.4, cy, c)
			ctx.draw_line(cx, cy - s * 1.4, cx, cy - s * 1.1, c)
			ctx.draw_line(cx, cy + s * 1.1, cx, cy + s * 1.4, c)
		}
		icon_freeze {
			// snowflake
			ctx.draw_line(cx - s, cy, cx + s, cy, c)
			ctx.draw_line(cx - s * 0.5, cy - s * 0.87, cx + s * 0.5, cy + s * 0.87, c)
			ctx.draw_line(cx - s * 0.5, cy + s * 0.87, cx + s * 0.5, cy - s * 0.87, c)
		}
		icon_dump {
			ctx.draw_rect_empty(cx - s * 0.8, cy - s, s * 1.6, s * 2, c)
			ctx.draw_line(cx - s * 0.5, cy - s * 0.5, cx + s * 0.5, cy - s * 0.5, c)
			ctx.draw_line(cx - s * 0.5, cy, cx + s * 0.5, cy, c)
			ctx.draw_line(cx - s * 0.5, cy + s * 0.5, cx + s * 0.2, cy + s * 0.5, c)
		}
		else {}
	}
}
