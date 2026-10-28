module vmem

import encoding.binary

// encode_scan_plan serializes a ScanPlan for agent-side scan offload
// (wire format v1, little-endian; see decode_scan_plan).
pub fn encode_scan_plan(p ScanPlan) []u8 {
	rn := p.pattern.bytes.len
	rc := p.pattern.ranges.len
	mut b := []u8{len: 82 + rn * 2 + rc * 22}
	mut i := 0
	b[i] = u8(p.kind)
	b[i + 1] = u8(p.op)
	i += 2
	binary.little_endian_put_u64(mut b[i..i + 8], f64_bits(p.value))
	binary.little_endian_put_u64(mut b[i + 8..i + 16], f64_bits(p.value2))
	binary.little_endian_put_u64(mut b[i + 16..i + 24], p.align)
	binary.little_endian_put_u32(mut b[i + 24..i + 28], u32(p.limit))
	i += 28
	binary.little_endian_put_u64(mut b[i..i + 8], p.filter.start)
	binary.little_endian_put_u64(mut b[i + 8..i + 16], p.filter.end)
	binary.little_endian_put_u64(mut b[i + 16..i + 24], p.filter.classes)
	binary.little_endian_put_u32(mut b[i + 24..i + 28], p.filter.prot_require)
	binary.little_endian_put_u32(mut b[i + 28..i + 32], p.filter.prot_reject)
	i += 32
	binary.little_endian_put_u64(mut b[i..i + 8], p.mask)
	binary.little_endian_put_u64(mut b[i + 8..i + 16], p.xor_key)
	i += 16
	binary.little_endian_put_u16(mut b[i..i + 2], u16(rn))
	i += 2
	for j in 0 .. rn {
		b[i + j] = p.pattern.bytes[j]
		b[i + rn + j] = p.pattern.mask[j]
	}
	i += rn * 2
	binary.little_endian_put_u16(mut b[i..i + 2], u16(rc))
	i += 2
	for rcv in p.pattern.ranges {
		binary.little_endian_put_u32(mut b[i..i + 4], u32(rcv.off))
		binary.little_endian_put_u64(mut b[i + 4..i + 12], f64_bits(rcv.lo))
		binary.little_endian_put_u64(mut b[i + 12..i + 20], f64_bits(rcv.hi))
		b[i + 20] = if rcv.is_float { u8(1) } else { u8(0) }
		b[i + 21] = u8(rcv.width)
		i += 22
	}
	return b[..i]
}

// f64_bits returns the raw bit pattern of v (little-endian host assumed).
fn f64_bits(v f64) u64 {
	return unsafe { *(&u64(&v)) }
}

// f64_from_bits rebuilds an f64 from its bit pattern.
fn f64_from_bits(v u64) f64 {
	return unsafe { *(&f64(&v)) }
}
