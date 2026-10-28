module sys

// read_bytes reads up to buf.len bytes of target memory at addr.
// Returns bytes actually read; an error carries the raw OS code.
pub fn read_bytes(h voidptr, addr u64, mut buf []u8) !int {
	mut got := usize(0)
	ok := C.ReadProcessMemory(h, voidptr(usize(addr)), buf.data, usize(buf.len), &got)
	if ok == 0 {
		return error_with_code('ReadProcessMemory addr=0x${addr:x} len=${buf.len}',
			int(C.GetLastError()))
	}
	return int(got)
}
