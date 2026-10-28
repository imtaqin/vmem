module vmem

// resume_process resumes every thread of the target pid.
pub fn resume_process(pid int) ! {
	mut b := new_local_backend(pid)!
	defer {
		b.detach() or {}
	}
	b.resume()!
}
