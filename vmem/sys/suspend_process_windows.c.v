module sys

// suspend_process pauses every thread of the target (freeze-scan support).
pub fn suspend_process(h voidptr) ! {
	tids := enumerate_threads(h)!
	mut failed := 0
	for tid in tids {
		th := C.OpenThread(win_thread_suspend_resume, 0, u32(tid))
		if th == unsafe { nil } {
			failed++
			continue
		}
		if C.SuspendThread(th) == 0xFFFFFFFF {
			failed++
		}
		C.CloseHandle(th)
	}
	if failed > 0 {
		return error_with_code('SuspendThread failed=${failed}/${tids.len}', int(C.GetLastError()))
	}
}
