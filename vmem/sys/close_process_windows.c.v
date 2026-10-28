module sys

// close_process closes an opaque handle from open_process.
pub fn close_process(h voidptr) {
	C.CloseHandle(h)
}
