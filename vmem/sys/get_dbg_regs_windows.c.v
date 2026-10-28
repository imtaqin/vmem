module sys

// get_dbg_regs reads the debug/control registers of a thread.
pub fn get_dbg_regs(tid int) !DbgRegs {
	th := C.OpenThread(win_thread_get_context | win_thread_suspend_resume, 0, u32(tid))
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
	C.ResumeThread(th)
	if ok == 0 {
		return error_with_code('GetThreadContext tid=${tid}', int(C.GetLastError()))
	}
	return DbgRegs{
		dr0:    ctx_get_u64(ctx, 72)
		dr1:    ctx_get_u64(ctx, 80)
		dr2:    ctx_get_u64(ctx, 88)
		dr3:    ctx_get_u64(ctx, 96)
		dr6:    ctx_get_u64(ctx, 104)
		dr7:    ctx_get_u64(ctx, 112)
		rip:    ctx_get_u64(ctx, 248)
		rsp:    ctx_get_u64(ctx, 152)
		rax:    ctx_get_u64(ctx, 120)
		eflags: u64(ctx_get_u32(ctx, 68))
	}
}
