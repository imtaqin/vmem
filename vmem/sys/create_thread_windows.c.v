module sys

// create_thread starts a thread in the target at start_addr (param passed
// as the single argument). Returns the thread handle.
pub fn create_thread(h voidptr, start_addr u64, param u64) !voidptr {
	mut tid := u32(0)
	th := C.CreateRemoteThread(h, unsafe { nil }, usize(0), voidptr(usize(start_addr)),
		voidptr(usize(param)), u32(0), &tid)
	if th == unsafe { nil } {
		return error_with_code('CreateRemoteThread 0x${start_addr:x}', int(C.GetLastError()))
	}
	return th
}
