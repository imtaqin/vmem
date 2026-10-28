module sys

// protect_memory changes page protection (sys.prot_* bits in and out);
// returns the previous protection as sys.prot_* bits.
pub fn protect_memory(h voidptr, addr u64, size u64, prot u32) !u32 {
	mut old := u32(0)
	if C.VirtualProtectEx(h, voidptr(usize(addr)), usize(size), win_prot_from_bits(prot), &old) == 0 {
		return error_with_code('VirtualProtectEx 0x${addr:x}', int(C.GetLastError()))
	}
	return win_prot_to_bits(old)
}
