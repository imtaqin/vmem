module sys

// resume_process continues the target with SIGCONT.
pub fn resume_process(h voidptr) ! {
	pid := pid_from_handle(h)
	if C.kill(pid, sig_cont) != 0 {
		return error_with_code('SIGCONT pid=${pid}', 0)
	}
}
