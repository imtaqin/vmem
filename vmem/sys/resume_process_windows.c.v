module sys

// resume_process resumes every thread of the target.
pub fn resume_process(h voidptr) ! {
	tids := enumerate_threads(h)!
	mut failed := 0
	for tid in tids {
		th := C.OpenThread(win_thread_suspend_resume, 0, u32(tid))
		if th == unsafe { nil } {
			failed++
			continue
		}
		if C.ResumeThread(th) == 0xFFFFFFFF {
			failed++
		}
		C.CloseHandle(th)
	}
	if failed > 0 {
		return error_with_code('ResumeThread failed=${failed}/${tids.len}', int(C.GetLastError()))
	}
}
