module main

import vmem

// Display formatting (one concern).

// fmt_row renders a result entry as a CE-style table line.
fn fmt_row(e vmem.ResultEntry) string {
	match e.kind {
		.byte, .word, .dword, .qword {
			return '0x${e.address:x}   prev ${i64(e.prev)}   cur ${i64(e.value)}   (${e.kind})'
		}
		else {
			return '0x${e.address:x}   prev ${e.prev:.4f}   cur ${e.value:.4f}   (${e.kind})'
		}
	}
}

// fmt_table_row renders an address-list entry.
fn fmt_table_row(t TableRow) string {
	frz := if t.frozen { '[F]' } else { '[ ]' }
	return '${frz}  ${t.desc}  0x${t.addr:x}  ${t.kind}  ${t.value}'
}

// fmt_hexdump renders a 256-byte hex view.
fn fmt_hexdump(start u64, data []u8) string {
	mut out := ''
	mut i := 0
	for i < data.len {
		mut hex := ''
		mut ascii := ''
		for j in 0 .. 16 {
			if i + j < data.len {
				b := data[i + j]
				hex += '${b:02x} '
				ascii += if b >= 0x20 && b < 0x7F { b.ascii_str() } else { '.' }
			}
		}
		out += '${start + u64(i):08x}  ${hex} ${ascii}\n'
		i += 16
	}
	return out
}
