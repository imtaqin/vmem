module vmem

// op_modules handles the modules operation, returning u32 count, then per module:
// u64 base, u64 size, u16 len + path.
fn (mut st ServeState) op_modules() ![]u8 {
	if !st.attached {
		return new_error(.not_attached, 'agent modules', 0)
	}
	mods := st.backend.enumerate_modules() or {
		return wrap_err(.access_denied, 'agent modules', err)
	}
	mut out := []u8{len: 4}
	out[0] = u8(u32(mods.len))
	out[1] = u8(u32(mods.len) >> 8)
	out[2] = u8(u32(mods.len) >> 16)
	out[3] = u8(u32(mods.len) >> 24)
	for m in mods {
		mut cell := []u8{len: 18}
		encode_u64_le(m.base, mut cell[0..8])
		encode_u64_le(m.size, mut cell[8..16])
		encode_u16_le(u16(m.path.len), mut cell[16..18])
		out << cell
		out << m.path.bytes()
	}
	return out
}
