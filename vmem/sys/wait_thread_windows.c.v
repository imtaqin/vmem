module sys

// wait_thread waits for a thread handle to exit (ms = timeout, -1 infinite).
pub fn wait_thread(th voidptr, ms int) ! {
	r := C.WaitForSingleObject(th, i32(ms))
	if r != 0 {
		return error_with_code('WaitForSingleObject r=${r}', int(C.GetLastError()))
	}
}
