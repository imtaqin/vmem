module sys

// write_bytes is an unsupported-platform fallback.
pub fn write_bytes(h voidptr, addr u64, buf []u8) !int {
	return error('write_bytes unsupported on this OS (addr=0x${addr:x})')
}
