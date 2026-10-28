module vmem

// read_u16 reads a little-endian u16 at addr of target pid.
pub fn read_u16(pid int, addr u64) !u16 {
	mut buf := []u8{len: 2}
	n := read_bytes(pid, addr, mut buf)!
	if n != 2 {
		return new_error(.short_io, 'read_u16 addr=0x${addr:x} got=${n}/2', 0)
	}
	return decode_u16_le(buf)
}
