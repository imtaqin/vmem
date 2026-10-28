module vmem

// read_u8 reads one byte at addr of target pid.
pub fn read_u8(pid int, addr u64) !u8 {
	mut buf := []u8{len: 1}
	n := read_bytes(pid, addr, mut buf)!
	if n != 1 {
		return new_error(.short_io, 'read_u8 addr=0x${addr:x} got=${n}/1', 0)
	}
	return buf[0]
}
