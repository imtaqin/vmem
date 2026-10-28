module vmem

// write_u64 writes a little-endian u64 at addr of target pid.
pub fn write_u64(pid int, addr u64, v u64) !int {
	mut buf := []u8{len: 8}
	encode_u64_le(v, mut buf)
	return checked_write(pid, addr, buf, 8, 'write_u64')
}
