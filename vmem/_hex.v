module vmem

// Internal hex parsing helpers (one concern; AGENTS.md §3).

fn hex_nibble(c u8) int {
	match true {
		c >= `0` && c <= `9` { return int(c - `0`) }
		c >= `a` && c <= `f` { return int(c - `a`) + 10 }
		c >= `A` && c <= `F` { return int(c - `A`) + 10 }
		else { return -1 }
	}
}

fn hex_byte(a u8, b u8) int {
	hi := hex_nibble(a)
	lo := hex_nibble(b)
	if hi < 0 || lo < 0 {
		return -1
	}
	return hi * 16 + lo
}

// hex_u64 parses a hex string (no 0x prefix) to u64; invalid digits stop it.
fn hex_u64(s string) u64 {
	mut v := u64(0)
	for i in 0 .. s.len {
		n := hex_nibble(s[i])
		if n < 0 {
			return v
		}
		v = v * 16 + u64(n)
	}
	return v
}
