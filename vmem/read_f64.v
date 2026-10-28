module vmem

// read_f64 reads a little-endian IEEE 754 f64 at addr of target pid.
pub fn read_f64(pid int, addr u64) !f64 {
	mut buf := []u8{len: 8}
	n := read_bytes(pid, addr, mut buf)!
	if n != 8 {
		return new_error(.short_io, 'read_f64 addr=0x${addr:x} got=${n}/8', 0)
	}
	return decode_f64_le(buf)
}
