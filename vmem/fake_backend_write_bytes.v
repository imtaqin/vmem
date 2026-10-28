module vmem

// write_bytes copies buf into the fake mapping at addr.
pub fn (mut b FakeBackend) write_bytes(addr u64, buf []u8) !int {
	if !b.attached {
		return new_error(.not_attached, 'write_bytes addr=0x${addr:x}', 0)
	}
	if buf.len == 0 {
		return 0
	}
	if addr < b.base || addr + u64(buf.len) > b.base + u64(b.mem.len) {
		return new_error(.range, 'write 0x${addr:x} len=${buf.len}', 0)
	}
	off := int(addr - b.base)
	for i in 0 .. buf.len {
		b.mem[off + i] = buf[i]
	}
	return buf.len
}
