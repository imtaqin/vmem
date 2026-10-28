module vmem

// pattern_from_text encodes text into an exact byte pattern (all mask 0xFF).
pub fn pattern_from_text(s string, enc TextEncoding) !ScanPattern {
	if s == '' {
		return new_error(.bad_pattern, 'empty text pattern', 0)
	}
	bytes := encode_text(s, enc)
	mut mask := []u8{len: bytes.len}
	for i in 0 .. mask.len {
		mask[i] = 0xFF
	}
	return ScanPattern{
		bytes: bytes
		mask:  mask
	}
}
