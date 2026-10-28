module vmem

// op_regions handles the regions operation, returning u32 count, then per region:
// u64 base, u64 size, u32 prot, u32 class, u16 len + name.
fn (mut st ServeState) op_regions() ![]u8 {
	if !st.attached {
		return new_error(.not_attached, 'agent regions', 0)
	}
	regions := st.backend.enumerate_regions() or {
		return wrap_err(.access_denied, 'agent regions', err)
	}
	mut out := []u8{len: 4}
	out[0] = u8(u32(regions.len))
	out[1] = u8(u32(regions.len) >> 8)
	out[2] = u8(u32(regions.len) >> 16)
	out[3] = u8(u32(regions.len) >> 24)
	for r in regions {
		mut cell := []u8{len: 26}
		encode_u64_le(r.base, mut cell[0..8])
		encode_u64_le(r.size, mut cell[8..16])
		encode_u32_le(r.prot, mut cell[16..20])
		encode_u32_le(u32(r.class), mut cell[20..24])
		encode_u16_le(u16(r.name.len), mut cell[24..26])
		out << cell
		out << r.name.bytes()
	}
	return out
}
