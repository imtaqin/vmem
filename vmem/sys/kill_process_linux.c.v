module sys

// kill_process terminates the target with SIGKILL (code is ignored on Linux).
pub fn kill_process(h voidptr, code int) ! {
	pid := pid_from_handle(h)
	if C.kill(pid, sig_kill) != 0 {
		return error_with_code('SIGKILL pid=${pid}', 0)
	}
}
