module vmem

import vmem.sys

// set_breakpoint places a hardware breakpoint/watchpoint at addr in every
// thread of the target (DR0-DR3 slots). size is 1, 2, 4 or 8 bytes
// (ignored for .execute). Returns the slot used.
pub fn (mut s DebugSession) set_breakpoint(addr u64, kind BreakKind, size int) !int {
	if !s.attached {
		return new_error(.not_attached, 'set_breakpoint 0x${addr:x}', 0)
	}
	mut slot := -1
	for i in 0 .. 4 {
		if !s.in_use[i] {
			slot = i
			break
		}
	}
	if slot < 0 {
		return new_error(.state, 'set_breakpoint: all 4 debug registers in use', 0)
	}
	rw := match kind {
		.execute { u64(0) }
		.write { u64(1) }
		.rw { u64(3) }
	}

	len := match size {
		1 { u64(0) }
		2 { u64(1) }
		8 { u64(2) }
		else { u64(3) } // 4
	}

	tids := sys.enumerate_threads(s.handle) or {
		return wrap_err(.access_denied, 'set_breakpoint threads', err)
	}
	for tid in tids {
		mut regs := sys.get_dbg_regs(tid) or { continue }
		match slot {
			0 { regs.dr0 = addr }
			1 { regs.dr1 = addr }
			2 { regs.dr2 = addr }
			else { regs.dr3 = addr }
		}

		// local enable bit (2*slot), RWn at 16+4*slot, LENn at 18+4*slot
		regs.dr7 |= u64(1) << u64(2 * slot)
		regs.dr7 &= ~(u64(3) << u64(16 + 4 * slot))
		regs.dr7 |= rw << u64(16 + 4 * slot)
		regs.dr7 &= ~(u64(3) << u64(18 + 4 * slot))
		regs.dr7 |= len << u64(18 + 4 * slot)
		sys.set_dbg_regs(tid, regs) or { continue }
	}
	s.slots[slot] = addr
	s.in_use[slot] = true
	return slot
}
