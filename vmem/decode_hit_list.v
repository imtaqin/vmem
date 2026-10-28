module vmem

import encoding.binary

// decode_hit_list parses the wire form written by encode_hit_list.
pub fn decode_hit_list(b []u8) !ScanHits {
	if b.len < 8 {
		return new_error(.protocol, 'hit list truncated (${b.len} bytes)', 0)
	}
	count := int(binary.little_endian_u32(b[0..4]))
	stride := int(binary.little_endian_u32(b[4..8]))
	need := 8 + count * 12 + count * stride
	if b.len < need {
		return new_error(.protocol, 'hit list truncated (${b.len} < ${need})', 0)
	}
	mut out := ScanHits{
		stride: stride
	}
	mut i := 8
	for _ in 0 .. count {
		out.addresses << binary.little_endian_u64(b[i..i + 8])
		i += 8
	}
	for j in 0 .. count * stride {
		out.raw << b[i + j]
	}
	i += count * stride
	for _ in 0 .. count {
		out.stable << binary.little_endian_u32(b[i..i + 4])
		i += 4
	}
	return out
}
