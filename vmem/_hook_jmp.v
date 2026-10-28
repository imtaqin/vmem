module vmem

// Internal jump encoders (one concern; AGENTS.md §3).
// x64 absolute jump (14 bytes): jmp qword ptr [rip+0]; dq target.
// arm64 (16 bytes): ldr x17, #8; br x17; .quad target.

fn jmp_len_for(arch HookArch) int {
	return if arch == .x64 { 14 } else { 16 }
}

fn jmp_abs(arch HookArch, target u64) []u8 {
	if arch == .x64 {
		mut b := []u8{len: 14}
		b[0] = 0xFF
		b[1] = 0x25
		encode_u64_le(target, mut b[6..14])
		return b
	}
	mut b := []u8{len: 16}
	// ldr x17, #8
	b[0] = 0x41
	b[1] = 0x00
	b[2] = 0x00
	b[3] = 0x58
	// br x17
	b[4] = 0x20
	b[5] = 0x02
	b[6] = 0x1F
	b[7] = 0xD6
	encode_u64_le(target, mut b[8..16])
	return b
}
