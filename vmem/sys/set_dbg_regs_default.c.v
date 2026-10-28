module sys

// set_dbg_regs is an unsupported-platform fallback.
pub fn set_dbg_regs(tid int, regs DbgRegs) ! {
	return error('set_dbg_regs unsupported on this OS')
}
