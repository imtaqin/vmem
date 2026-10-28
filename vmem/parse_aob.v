module vmem

// parse_aob parses a CE/GameGuardian-style byte pattern:
// space-separated hex byte tokens with "?"/"??" wildcards, single-nibble
// wildcards ("?F", "A?"), and longer nibble strings ("0B?0" = 2 bytes).
// Examples: "48 8B ?? C3", "5C E3 0B", "0B?0".
pub fn parse_aob(spec string) !ScanPattern {
	mut bytes := []u8{}
	mut mask := []u8{}
	for tok in spec.split(' ') {
		t := tok.trim_space()
		if t == '' {
			continue
		}
		if t == '??' || t == '?' {
			bytes << u8(0)
			mask << u8(0)
			continue
		}
		// nibble string: even length >= 2, each char hex or '?'
		if t.len >= 2 && t.len % 2 == 0 && is_hex_nibbles(t) {
			mut j := 0
			for j < t.len {
				hi_c := t[j]
				lo_c := t[j + 1]
				mut v := u8(0)
				mut m := u8(0)
				if hi_c != `?` {
					v |= u8(hex_nibble(hi_c)) << 4
					m |= u8(0xF0)
				}
				if lo_c != `?` {
					v |= u8(hex_nibble(lo_c))
					m |= u8(0x0F)
				}
				bytes << v
				mask << m
				j += 2
			}
			continue
		}
		return new_error(.bad_pattern, 'aob token "${t}" in "${spec}"', 0)
	}
	if bytes.len == 0 {
		return new_error(.bad_pattern, 'empty aob pattern "${spec}"', 0)
	}
	return ScanPattern{
		bytes: bytes
		mask:  mask
	}
}

// is_hex_nibbles reports whether every char of t is a hex digit or '?'.
fn is_hex_nibbles(t string) bool {
	for i in 0 .. t.len {
		c := t[i]
		if c == `?` {
			continue
		}
		if hex_nibble(c) < 0 {
			return false
		}
	}
	return true
}
