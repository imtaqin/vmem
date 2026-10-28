module vmem

import encoding.binary

// decode_scan_plan parses the wire form written by encode_scan_plan.
pub fn decode_scan_plan(b []u8) !ScanPlan {
	if b.len < 80 {
		return new_error(.protocol, 'scan plan truncated (${b.len} bytes)', 0)
	}
	kind := unsafe { ValueKind(b[0]) }
	op := unsafe { CompareOp(b[1]) }
	value := f64_from_bits(binary.little_endian_u64(b[2..10]))
	value2 := f64_from_bits(binary.little_endian_u64(b[10..18]))
	align := binary.little_endian_u64(b[18..26])
	limit := int(binary.little_endian_u32(b[26..30]))
	filter := ScanFilter{
		start:        binary.little_endian_u64(b[30..38])
		end:          binary.little_endian_u64(b[38..46])
		classes:      binary.little_endian_u64(b[46..54])
		prot_require: binary.little_endian_u32(b[54..58])
		prot_reject:  binary.little_endian_u32(b[58..62])
	}
	mask := binary.little_endian_u64(b[62..70])
	xor_key := binary.little_endian_u64(b[70..78])
	mut i := 78
	rn := int(binary.little_endian_u16(b[i..i + 2]))
	i += 2
	if b.len < i + rn * 2 + 2 {
		return new_error(.protocol, 'scan plan pattern truncated', 0)
	}
	bytes := b[i..i + rn].clone()
	mbytes := b[i + rn..i + rn * 2].clone()
	i += rn * 2
	rc := int(binary.little_endian_u16(b[i..i + 2]))
	i += 2
	if b.len < i + rc * 22 {
		return new_error(.protocol, 'scan plan ranges truncated', 0)
	}
	mut ranges := []CellRange{}
	for _ in 0 .. rc {
		off := int(binary.little_endian_u32(b[i..i + 4]))
		lo := f64_from_bits(binary.little_endian_u64(b[i + 4..i + 12]))
		hi := f64_from_bits(binary.little_endian_u64(b[i + 12..i + 20]))
		isf := b[i + 20] == 1
		w := int(b[i + 21])
		ranges << CellRange{
			off:      off
			lo:       lo
			hi:       hi
			is_float: isf
			width:    w
		}
		i += 22
	}
	return ScanPlan{
		kind:    kind
		op:      op
		value:   value
		value2:  value2
		align:   align
		limit:   limit
		filter:  filter
		mask:    mask
		xor_key: xor_key
		pattern: ScanPattern{
			bytes:  bytes
			mask:   mbytes
			ranges: ranges
		}
	}
}
