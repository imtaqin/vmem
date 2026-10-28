module sys

// suspend_process stops the target with SIGSTOP.
pub fn suspend_process(h voidptr) ! {
	pid := pid_from_handle(h)
	if C.kill(pid, sig_stop) != 0 {
		return error_with_code('SIGSTOP pid=${pid}', 0)
	}
}
