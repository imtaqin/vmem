module sys

// free_memory releases a range allocated by alloc_memory.
pub fn free_memory(h voidptr, addr u64) ! {
	if C.VirtualFreeEx(h, voidptr(usize(addr)), 0, u32(0x8000)) == 0 {
		return error_with_code('VirtualFreeEx 0x${addr:x}', int(C.GetLastError()))
	}
}
