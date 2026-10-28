module sys

// thread_exit_code returns the exit code of an exited thread.
pub fn thread_exit_code(th voidptr) !u64 {
	mut code := u32(0)
	if C.GetExitCodeThread(th, &code) == 0 {
		return error_with_code('GetExitCodeThread', int(C.GetLastError()))
	}
	return u64(code)
}
