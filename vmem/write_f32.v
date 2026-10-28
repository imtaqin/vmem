module vmem

// write_f32 writes a little-endian IEEE 754 f32 at addr of target pid.
pub fn write_f32(pid int, addr u64, v f32) !int {
	mut buf := []u8{len: 4}
	encode_f32_le(v, mut buf)
	return checked_write(pid, addr, buf, 4, 'write_f32')
}
