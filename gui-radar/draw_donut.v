module main

import gg
import math

// draw_donut renders the memory-map donut with a class legend
// (docs/GUI.md — unique to Radar).
fn draw_donut(mut ctx gg.Context, app &App) {
	// card
	ctx.draw_rect_filled(920, 136, 360, 420, surface)
	ctx.draw_line(920, 136, 920, 556, border)
	ctx.draw_text(944, 166, 'MEMORY MAP', gg.TextCfg{ color: muted, size: 13 })
	ctx.draw_line(944, 176, 1256, 176, border)
	cx := f32(1100)
	cy := f32(300)
	r_out := f32(96)
	r_in := f32(58)
	if app.regions.len == 0 {
		draw_icon(mut ctx, icon_target, cx, cy, 30, border)
		ctx.draw_text(1024, 420, 'attach to see the map', gg.TextCfg{ color: muted, size: 14 })
		return
	}
	mut totals := []f64{len: 16}
	mut grand := f64(0)
	for r in app.regions {
		totals[int(r.class)] += f64(r.size)
		grand += f64(r.size)
	}
	if grand <= 0 {
		return
	}
	mut ang := f64(-math.pi / 2)
	names := ['code app', 'code sys', 'java heap', 'c heap', 'c alloc', 'c bss', 'c data', 'stack',
		'anon', 'ashmem', 'video', 'other']
	for class in 0 .. 12 {
		t := totals[class]
		if t <= 0 {
			continue
		}
		span := t / grand * 2.0 * math.pi
		col := class_color(class)
		mut steps := int(span / 0.1) + 1
		if steps > 72 {
			steps = 72
		}
		for k in 0 .. steps {
			a0 := ang + span * f64(k) / f64(steps)
			a1 := ang + span * f64(k + 1) / f64(steps)
			x0o := cx + r_out * f32(math.cos(a0))
			y0o := cy + r_out * f32(math.sin(a0))
			x1o := cx + r_out * f32(math.cos(a1))
			y1o := cy + r_out * f32(math.sin(a1))
			x0i := cx + r_in * f32(math.cos(a0))
			y0i := cy + r_in * f32(math.sin(a0))
			x1i := cx + r_in * f32(math.cos(a1))
			y1i := cy + r_in * f32(math.sin(a1))
			ctx.draw_triangle_filled(x0o, y0o, x1o, y1o, x1i, y1i, col)
			ctx.draw_triangle_filled(x0o, y0o, x1i, y1i, x0i, y0i, col)
		}
		ang += span
	}
	// center readout
	gb := if grand > 1024.0 * 1024.0 * 1024.0 {
		'${grand / 1024.0 / 1024.0 / 1024.0:.1f} GB'
	} else {
		'${grand / 1024.0 / 1024.0:.0f} MB'
	}
	ctx.draw_text(1100 - gb.len * 5, 296, gb, gg.TextCfg{ color: fg, size: 19 })
	ctx.draw_text(1100 - 40, 318, '${app.regions.len} regions', gg.TextCfg{ color: muted, size: 12 })
	// legend: top 5 classes by size
	mut order := []int{}
	for class in 0 .. 12 {
		order << class
	}
	for i in 0 .. order.len {
		for j in i + 1 .. order.len {
			if totals[order[j]] > totals[order[i]] {
				t := order[i]
				order[i] = order[j]
				order[j] = t
			}
		}
	}
	mut ly := 442
	mut shown := 0
	for class in order {
		if totals[class] <= 0 || shown >= 5 {
			continue
		}
		pct := totals[class] / grand * 100.0
		ctx.draw_rect_filled(952, f32(ly - 10), 12, 12, class_color(class))
		ctx.draw_text(974, ly, names[class], gg.TextCfg{ color: fg, size: 13 })
		ctx.draw_text(1180, ly, '${pct:.1f}%', gg.TextCfg{ color: muted, size: 13 })
		ly += 22
		shown++
	}
}
