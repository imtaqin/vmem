module vmem

import vmem.sys

// speedhack_install detours the target's GetTickCount64 to a cave that
// returns a virtual clock driven by speedhack_tick (factor = speed
// multiplier, e.g. 0.1 = 10x slower, 10 = 10x faster). Call
// speedhack_tick periodically with the real elapsed ms.
pub fn speedhack_install(mut b LocalBackend, factor f64) !Speedhack {
	// vlib time.ticks() calls GetTickCount (time.c.v)
	tick_addr := sys.find_export('kernel32.dll', 'GetTickCount') or {
		return wrap_err(.unsupported, 'speedhack_install find GetTickCount', err)
	}
	page := b.alloc_memory(4096, prot_read | prot_write | prot_exec) or {
		return wrap_err(.unsupported, 'speedhack_install alloc', err)
	}
	// cave: mov rax, [rip+rel]; ret   (48 8B 05 rel32 C3), slot at +64
	data_addr := page + 64
	mut cave := []u8{len: 7}
	cave[0] = 0x48
	cave[1] = 0x8B
	cave[2] = 0x05
	rel := i32(i64(data_addr) - i64(page + 7))
	encode_u32_le(u32(rel), mut cave[3..7])
	mut pad := []u8{len: 64}
	pad[0] = 0xC3
	mut body := cave.clone()
	body << pad
	patch_bytes(mut b, page, body) or {
		b.free_memory(page) or {}
		return err
	}
	h := install_hook(mut b, .x64, tick_addr, page, 14) or {
		b.free_memory(page) or {}
		return err
	}
	// virtual clock starts at 0: callers observe deltas (speedhack_tick);
	// reading the raw start would need a position-independent prologue,
	// which GetTickCount64 does not have when relocated to a trampoline.
	return Speedhack{
		hook:        h
		page:        page
		data_addr:   data_addr
		factor:      factor
		virtual_now: 0
	}
}
