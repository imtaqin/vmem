module sys

// Debug-side register snapshot (normalized, OS-independent).
pub struct DbgRegs {
pub mut:
	dr0    u64
	dr1    u64
	dr2    u64
	dr3    u64
	dr6    u64
	dr7    u64
	rip    u64
	rsp    u64
	rax    u64
	eflags u64
}

// Debug event codes (WaitForDebugEvent dwDebugEventCode).
pub const dbg_exception = u32(1)
pub const dbg_exit_process = u32(5)
pub const dbg_exception_single_step = u32(0x80000004)
pub const dbg_exception_breakpoint = u32(0x80000003)

// DebugEvent is one queued debug event (code 0 = wait timeout).
pub struct DebugEvent {
pub:
	code u32
	pid  int
	tid  int
}
