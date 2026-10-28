module vmem

// write_bytes writes buf at addr of target pid; returns bytes written.
pub fn write_bytes(pid int, addr u64, buf []u8) !int {
	mut b := new_local_backend(pid)!
	defer {
		b.detach() or {}
	}
	return b.write_bytes(addr, buf)
}
