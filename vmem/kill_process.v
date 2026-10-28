module vmem

// kill_process terminates the target pid.
pub fn kill_process(pid int) ! {
	mut b := new_local_backend(pid)!
	defer {
		b.detach() or {}
	}
	b.kill()!
}
