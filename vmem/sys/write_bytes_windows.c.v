module sys

// write_bytes writes buf to target memory at addr.
// Returns bytes actually written; an error carries the raw OS code.
pub fn write_bytes(h voidptr, addr u64, buf []u8) !int {
	mut put := usize(0)
	ok := C.WriteProcessMemory(h, voidptr(usize(addr)), buf.data, usize(buf.len), &put)
	if ok == 0 {
		return error_with_code('WriteProcessMemory addr=0x${addr:x} len=${buf.len}',
			int(C.GetLastError()))
	}
	return int(put)
}
