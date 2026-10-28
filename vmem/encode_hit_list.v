module vmem

import encoding.binary

// encode_hit_list serializes scan hits for transport:
// u32 count | u32 stride | count*u64 addresses | count*stride raw | count*u32 stable.
pub fn encode_hit_list(addresses []u64, raw []u8, stable []u32, stride int) []u8 {
	count := addresses.len
	mut b := []u8{len: 8 + count * 12 + count * stride}
	binary.little_endian_put_u32(mut b[0..4], u32(count))
	binary.little_endian_put_u32(mut b[4..8], u32(stride))
	mut i := 8
	for a in addresses {
		binary.little_endian_put_u64(mut b[i..i + 8], a)
		i += 8
	}
	for j in 0 .. count * stride {
		b[i + j] = raw[j]
	}
	i += count * stride
	for s in stable {
		binary.little_endian_put_u32(mut b[i..i + 4], s)
		i += 4
	}
	return b
}
