module vmem

// BreakKind is the access type that triggers a data breakpoint (DR7 RWn).
pub enum BreakKind {
	execute
	write
	rw
}

// DebugHit reports one caught debug exception with the register state.
pub struct DebugHit {
pub:
	tid  int
	code u32
	rip  u64
	dr6  u64
	regs DbgRegsView
}

// DbgRegsView is the public view of the debug/control registers.
pub struct DbgRegsView {
pub:
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
