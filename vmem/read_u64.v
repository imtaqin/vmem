module vmem

// read_u64 reads a little-endian u64 at addr of target pid.
pub fn read_u64(pid int, addr u64) !u64 {
	mut buf := []u8{len: 8}
	n := read_bytes(pid, addr, mut buf)!
	if n != 8 {
		return new_error(.short_io, 'read_u64 addr=0x${addr:x} got=${n}/8', 0)
	}
	return decode_u64_le(buf)
}
