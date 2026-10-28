module vmem

// Internal wire string helpers (one concern; AGENTS.md §3).
// Format: u16 length + bytes.

fn wire_str(s string) []u8 {
	mut b := []u8{len: 2 + s.len}
	b[0] = u8(u16(s.len))
	b[1] = u8(u16(s.len) >> 8)
	for i in 0 .. s.len {
		b[2 + i] = s[i]
	}
	return b
}

// wire_read_str reads one wire string at idx; returns (s, next_idx).
fn wire_read_str(b []u8, idx int) (string, int) {
	if idx + 2 > b.len {
		return '', b.len
	}
	n := int(decode_u16_le(b[idx..idx + 2]))
	end := idx + 2 + n
	if end > b.len {
		return '', b.len
	}
	return b[idx + 2..end].bytestr(), end
}
