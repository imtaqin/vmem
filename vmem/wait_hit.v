module vmem

import vmem.sys
import time

// wait_hit pumps debug events until a breakpoint/watchpoint/step exception
// arrives, returning the register state at the hit. Other events are
// continued transparently. Returns a .state error on timeout.
pub fn (mut s DebugSession) wait_hit(timeout_ms int) !DebugHit {
	if !s.attached {
		return new_error(.not_attached, 'wait_hit', 0)
	}
	deadline := time.ticks() + i64(timeout_ms)
	for {
		mut wait_ms := -1
		if timeout_ms > 0 {
			wait_ms = int(deadline - time.ticks())
			if wait_ms <= 0 {
				return new_error(.state, 'wait_hit timeout', 0)
			}
		}
		evt := sys.debug_wait_event(wait_ms) or { return wrap_err(.access_denied, 'wait_hit', err) }
		if evt.code == 0 {
			continue
		}
		mut hit := false
		mut view := DbgRegsView{}
		if evt.code == sys.dbg_exception {
			regs := sys.get_dbg_regs(evt.tid) or { sys.DbgRegs{} }
			// DR6 bits 0-3: hardware slot hit; DR6.BS (bit 14): single-step
			if regs.dr6 & 0xF != 0 || regs.dr6 & 0x4000 != 0 {
				hit = true
			}
			view = DbgRegsView{
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
		sys.debug_continue(evt.pid, evt.tid) or {
			return wrap_err(.access_denied, 'wait_hit continue', err)
		}
		if hit {
			return DebugHit{
				tid:  evt.tid
				code: evt.code
				rip:  view.rip
				dr6:  view.dr6
				regs: view
			}
		}
		if evt.code == sys.dbg_exit_process {
			return new_error(.process_gone, 'wait_hit: target exited', 0)
		}
	}
	return new_error(.state, 'wait_hit exited loop', 0)
}
