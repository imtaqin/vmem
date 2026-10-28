module vmem

// write_u8 writes one byte at addr of target pid.
pub fn write_u8(pid int, addr u64, v u8) !int {
	buf := [v]!
	return checked_write(pid, addr, buf, 1, 'write_u8')
}
