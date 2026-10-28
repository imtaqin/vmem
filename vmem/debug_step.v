module vmem

import vmem.sys

// step arms the trap flag (EFlags.TF) of a thread so the next wait_hit
// returns after one instruction (single-step model).
pub fn (mut s DebugSession) step(tid int) ! {
	if !s.attached {
		return new_error(.not_attached, 'step tid=${tid}', 0)
	}
	mut regs := sys.get_dbg_regs(tid) or {
		return wrap_err(.access_denied, 'step get regs tid=${tid}', err)
	}
	regs.eflags |= 0x100
	sys.set_dbg_regs(tid, regs) or {
		return wrap_err(.access_denied, 'step set regs tid=${tid}', err)
	}
}
