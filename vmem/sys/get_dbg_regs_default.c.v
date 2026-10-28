module sys

// get_dbg_regs is an unsupported-platform fallback.
pub fn get_dbg_regs(tid int) !DbgRegs {
	return error('get_dbg_regs unsupported on this OS')
}
