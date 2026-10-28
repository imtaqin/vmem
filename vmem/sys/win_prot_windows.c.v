module sys

// Windows protection-bit mapping (one concern; AGENTS.md §3).
// sys.prot_* bits <-> PAGE_* constants; both directions used by
// protect_memory so its in/out units are symmetric.

fn win_prot_from_bits(prot u32) u32 {
	r := prot & prot_read != 0
	w := prot & prot_write != 0
	x := prot & prot_exec != 0
	return match true {
		x && w { u32(0x40) } // PAGE_EXECUTE_READWRITE
		x && r { u32(0x20) } // PAGE_EXECUTE_READ
		x { u32(0x10) } // PAGE_EXECUTE
		w { u32(0x04) } // PAGE_READWRITE
		r { u32(0x02) } // PAGE_READONLY
		else { u32(0x01) } // PAGE_NOACCESS
	}
}

// win_prot_to_bits normalizes PAGE_* protection to sys.prot_* bits.
fn win_prot_to_bits(p u32) u32 {
	low := p & 0xFF
	mut prot := u32(0)
	if low != 0x01 {
		// everything except PAGE_NOACCESS is readable
		prot |= prot_read
	}
	match low {
		0x04, 0x08, 0x40, 0x80 { prot |= prot_write }
		else {}
	}

	match low {
		0x10, 0x20, 0x40, 0x80 { prot |= prot_exec }
		else {}
	}

	if low == 0x08 || low == 0x80 {
		// PAGE_WRITECOPY / PAGE_EXECUTE_WRITECOPY
		prot |= prot_cow
	}
	return prot
}
