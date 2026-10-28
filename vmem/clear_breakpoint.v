module vmem

import vmem.sys

// clear_breakpoint removes the breakpoint in slot from every thread.
pub fn (mut s DebugSession) clear_breakpoint(slot int) ! {
	if slot < 0 || slot >= 4 || !s.in_use[slot] {
		return new_error(.range, 'clear_breakpoint slot=${slot}', 0)
	}
	tids := sys.enumerate_threads(s.handle) or {
		return wrap_err(.access_denied, 'clear_breakpoint threads', err)
	}
	for tid in tids {
		mut regs := sys.get_dbg_regs(tid) or { continue }
		match slot {
			0 { regs.dr0 = 0 }
			1 { regs.dr1 = 0 }
			2 { regs.dr2 = 0 }
			else { regs.dr3 = 0 }
		}

		regs.dr7 &= ~(u64(1) << u64(2 * slot))
		sys.set_dbg_regs(tid, regs) or { continue }
	}
	s.slots[slot] = 0
	s.in_use[slot] = false
}
