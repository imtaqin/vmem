module sys

// set_dbg_regs writes the debug/control registers of a thread (dr7 and
// eflags are taken from regs as-is).
pub fn set_dbg_regs(tid int, regs DbgRegs) ! {
	th := C.OpenThread(win_thread_get_context | win_thread_set_context | win_thread_suspend_resume,
		0, u32(tid))
	if th == unsafe { nil } {
		return error_with_code('OpenThread tid=${tid}', int(C.GetLastError()))
	}
	defer {
		C.CloseHandle(th)
	}
	raw, ctx := context_alloc()
	defer {
		unsafe {
			free(raw)
		}
	}
	// context calls need the thread stopped
	C.SuspendThread(th)
	ctx_set_u32(ctx, 48, win_ctx_debug_regs | win_ctx_control)
	ok := C.vmem_GetThreadContext(th, ctx)
	if ok == 0 {
		C.ResumeThread(th)
		return error_with_code('GetThreadContext tid=${tid}', int(C.GetLastError()))
	}
	ctx_set_u64(ctx, 72, regs.dr0)
	ctx_set_u64(ctx, 80, regs.dr1)
	ctx_set_u64(ctx, 88, regs.dr2)
	ctx_set_u64(ctx, 96, regs.dr3)
	ctx_set_u64(ctx, 104, regs.dr6)
	ctx_set_u64(ctx, 112, regs.dr7)
	ctx_set_u32(ctx, 68, u32(regs.eflags))
	ok2 := C.vmem_SetThreadContext(th, ctx)
	C.ResumeThread(th)
	if ok2 == 0 {
		return error_with_code('SetThreadContext tid=${tid}', int(C.GetLastError()))
	}
}
