module sys

// write_bytes writes target memory via process_vm_writev, falling back to
// pwrite on /proc/<pid>/mem when the fast path is denied.
pub fn write_bytes(h voidptr, addr u64, buf []u8) !int {
	pid := pid_from_handle(h)
	mut local := Iovec{
		iov_base: buf.data
		iov_len:  usize(buf.len)
	}
	mut remote := Iovec{
		iov_base: voidptr(usize(addr))
		iov_len:  usize(buf.len)
	}
	n := C.process_vm_writev(pid, voidptr(&local), 1, voidptr(&remote), 1, 0)
	if n > 0 {
		return int(n)
	}
	fd := proc_mem_fd(pid) or {
		return error_with_code('write_bytes 0x${addr:x}: process_vm_writev + ${err.msg()}', 0)
	}
	defer {
		C.close(fd)
	}
	put := C.pwrite(fd, buf.data, usize(buf.len), i64(addr))
	if put < 0 {
		return error_with_code('write_bytes pwrite 0x${addr:x}', 0)
	}
	return int(put)
}
