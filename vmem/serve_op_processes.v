module vmem

// op_processes handles the processes operation, returning u32 count, then per process:
// i32 pid, u16 len + name, u16 len + path.
fn (mut st ServeState) op_processes() ![]u8 {
	procs := enumerate_processes() or { return wrap_err(.access_denied, 'agent processes', err) }
	mut out := []u8{len: 4}
	out[0] = u8(u32(procs.len))
	out[1] = u8(u32(procs.len) >> 8)
	out[2] = u8(u32(procs.len) >> 16)
	out[3] = u8(u32(procs.len) >> 24)
	for p in procs {
		mut cell := []u8{len: 6}
		encode_u32_le(u32(p.pid), mut cell[0..4])
		encode_u16_le(u16(p.name.len), mut cell[4..6])
		out << cell
		out << p.name.bytes()
		out << wire_str(p.path)
	}
	return out
}
