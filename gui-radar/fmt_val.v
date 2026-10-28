module main

import vmem

// fmt_val renders a scanned value for display: integer kinds as integers
// with hex, float kinds as decimals (no scientific notation for scalars).
fn fmt_val(kind vmem.ValueKind, v f64) string {
	match kind {
		.byte, .word, .dword, .qword {
			iv := i64(v)
			return '${iv}  (0x${u64(iv):x})'
		}
		else {
			return '${v:.4f}'
		}
	}
}

// fmt_delta renders a value delta compactly (integers stay integers).
fn fmt_delta(kind vmem.ValueKind, d f64) string {
	match kind {
		.byte, .word, .dword, .qword {
			return '${i64(d)}'
		}
		else {
			return '${d:.4f}'
		}
	}
}
