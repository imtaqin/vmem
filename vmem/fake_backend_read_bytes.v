module vmem

// read_bytes copies buf.len bytes at addr out of the fake mapping.
pub fn (mut b FakeBackend) read_bytes(addr u64, mut buf []u8) !int {
	if !b.attached {
		return new_error(.not_attached, 'read_bytes addr=0x${addr:x}', 0)
	}
	if buf.len == 0 {
		return 0
	}
	if addr < b.base || addr + u64(buf.len) > b.base + u64(b.mem.len) {
		return new_error(.range, 'read 0x${addr:x} len=${buf.len}', 0)
	}
	off := int(addr - b.base)
	for i in 0 .. buf.len {
		buf[i] = b.mem[off + i]
	}
	return buf.len
}
