module main

import gg

// Radar theme tokens (docs/GUI.md §1). Dark-first, hairline borders,
// accent reserved for live state.

const bg = gg.rgb(14, 17, 22)
const surface = gg.rgb(21, 26, 34)
const surface_hi = gg.rgb(28, 34, 45)
const fg = gg.rgb(220, 226, 235)
const muted = gg.rgb(120, 130, 148)
const border = gg.rgb(45, 52, 66)
const accent = gg.rgb(64, 201, 214)
const success = gg.rgb(94, 200, 130)
const warning = gg.rgb(224, 180, 90)
const errc = gg.rgb(224, 90, 90)
const c1 = gg.rgb(64, 201, 214)
const c2 = gg.rgb(155, 130, 224)
const c3 = gg.rgb(224, 130, 170)
const c4 = gg.rgb(224, 180, 90)
const c5 = gg.rgb(94, 200, 130)
const c6 = gg.rgb(110, 140, 224)

// class_color maps a RegionClass to its donut series color.
fn class_color(c int) gg.Color {
	return match c {
		0 { c1 } // code_app
		1 { c6 } // code_sys
		2 { c3 } // java_heap
		3 { c2 } // c_heap
		4 { c4 } // c_alloc
		5 { c5 } // c_bss
		6 { c1 } // c_data
		7 { c2 } // stack
		8 { c4 } // anonymous
		9 { c3 } // ashmem
		10 { c6 } // video
		else { muted }
	}
}
