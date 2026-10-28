module sys

// read_bytes is an unsupported-platform fallback.
pub fn read_bytes(h voidptr, addr u64, mut buf []u8) !int {
	return error('read_bytes unsupported on this OS (addr=0x${addr:x})')
}
