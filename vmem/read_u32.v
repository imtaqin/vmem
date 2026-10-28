module vmem

// read_u32 reads a little-endian u32 at addr of target pid.
pub fn read_u32(pid int, addr u64) !u32 {
	mut buf := []u8{len: 4}
	n := read_bytes(pid, addr, mut buf)!
	if n != 4 {
		return new_error(.short_io, 'read_u32 addr=0x${addr:x} got=${n}/4', 0)
	}
	return decode_u32_le(buf)
}
