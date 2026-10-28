module sys

// Linux/Android C interop declarations (grouped exception; AGENTS.md §3):
// process_vm_* (preferred) and /proc/<pid>/mem fallback.

#include <sys/uio.h>
#include <fcntl.h>
#include <signal.h>

fn C.process_vm_readv(int, voidptr, usize, voidptr, usize, usize) isize
fn C.process_vm_writev(int, voidptr, usize, voidptr, usize, usize) isize
fn C.open(&char, int, int) int
fn C.pread(int, voidptr, usize, i64) isize
fn C.pwrite(int, voidptr, usize, i64) isize
fn C.close(int) int
fn C.kill(int, int) int

struct Iovec {
mut:
	iov_base voidptr
	iov_len  usize
}

pub const sig_stop = 19 // SIGSTOP
pub const sig_cont = 18 // SIGCONT
pub const sig_kill = 9 // SIGKILL

// pseudo_handle wraps a pid as the opaque sys handle on Linux.
fn pseudo_handle(pid int) voidptr {
	return voidptr(usize(pid))
}

fn pid_from_handle(h voidptr) int {
	return int(usize(h))
}

// proc_mem_fd opens /proc/<pid>/mem for the fallback path.
fn proc_mem_fd(pid int) !int {
	path := '/proc/${pid}/mem'
	fd := C.open(&char(path.str), 2, 0) // O_RDWR
	if fd < 0 {
		return error_with_code('open ${path}', 0)
	}
	return fd
}
