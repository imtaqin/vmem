module vmem

// suspend_process pauses every thread of the target pid.
pub fn suspend_process(pid int) ! {
	mut b := new_local_backend(pid)!
	defer {
		b.detach() or {}
	}
	b.suspend()!
}
