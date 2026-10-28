module vmem

// write_u32 writes a little-endian u32 at addr of target pid.
pub fn write_u32(pid int, addr u64, v u32) !int {
	mut buf := []u8{len: 4}
	encode_u32_le(v, mut buf)
	return checked_write(pid, addr, buf, 4, 'write_u32')
}
