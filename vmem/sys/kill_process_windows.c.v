module sys

// kill_process terminates the target with the given exit code.
pub fn kill_process(h voidptr, code int) ! {
	if !C.TerminateProcess(h, u32(code)) {
		return error_with_code('TerminateProcess code=${code}', int(C.GetLastError()))
	}
}
