module vmem

// read_bytes reads up to buf.len bytes at addr of target pid.
pub fn read_bytes(pid int, addr u64, mut buf []u8) !int {
	mut b := new_local_backend(pid)!
	defer {
		b.detach() or {}
	}
	return b.read_bytes(addr, mut buf)
}
