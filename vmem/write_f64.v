module vmem

// write_f64 writes a little-endian IEEE 754 f64 at addr of target pid.
pub fn write_f64(pid int, addr u64, v f64) !int {
	mut buf := []u8{len: 8}
	encode_f64_le(v, mut buf)
	return checked_write(pid, addr, buf, 8, 'write_f64')
}
