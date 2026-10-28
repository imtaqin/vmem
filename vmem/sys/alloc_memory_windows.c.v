module sys

// alloc_memory reserves size bytes in the target (MEM_COMMIT|RESERVE,
// PAGE_EXECUTE_READWRITE). Returns the remote address.
pub fn alloc_memory(h voidptr, size u64, prot u32) !u64 {
	p := C.VirtualAllocEx(h, unsafe { nil }, usize(size), u32(0x3000), win_prot_from_bits(prot))
	if p == unsafe { nil } {
		return error_with_code('VirtualAllocEx size=${size}', int(C.GetLastError()))
	}
	return u64(usize(p))
}
