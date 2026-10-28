module vmem

// write_u16 writes a little-endian u16 at addr of target pid.
pub fn write_u16(pid int, addr u64, v u16) !int {
	mut buf := []u8{len: 2}
	encode_u16_le(v, mut buf)
	return checked_write(pid, addr, buf, 2, 'write_u16')
}
