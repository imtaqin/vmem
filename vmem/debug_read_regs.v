module vmem

import vmem.sys

// read_regs returns the debug/control register state of a thread.
pub fn (mut s DebugSession) read_regs(tid int) !DbgRegsView {
	regs := sys.get_dbg_regs(tid) or {
		return wrap_err(.access_denied, 'read_regs tid=${tid}', err)
	}
	return DbgRegsView{
		dr0:    regs.dr0
		dr1:    regs.dr1
		dr2:    regs.dr2
		dr3:    regs.dr3
		dr6:    regs.dr6
		dr7:    regs.dr7
		rip:    regs.rip
		rsp:    regs.rsp
		rax:    regs.rax
		eflags: regs.eflags
	}
}
