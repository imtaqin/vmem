module vmem

// read_f32 reads a little-endian IEEE 754 f32 at addr of target pid.
pub fn read_f32(pid int, addr u64) !f32 {
	mut buf := []u8{len: 4}
	n := read_bytes(pid, addr, mut buf)!
	if n != 4 {
		return new_error(.short_io, 'read_f32 addr=0x${addr:x} got=${n}/4', 0)
	}
	return decode_f32_le(buf)
}
