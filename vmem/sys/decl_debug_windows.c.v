module sys

// Windows debug-event and CONTEXT mirrors + C prototypes for the debug
// layer (grouped declaration exception; AGENTS.md §3).
// x64 CONTEXT offsets (winnt.h): ContextFlags 48, MxCsr 52, EFlags 68,
// Dr0 72, Dr1 80, Dr2 88, Dr3 96, Dr6 104, Dr7 112, Rip 248.

fn C.vmem_DebugActiveProcess(u32) int
fn C.vmem_DebugActiveProcessStop(u32) int
fn C.vmem_DebugSetProcessKillOnExit(u32) int
fn C.vmem_WaitForDebugEvent(voidptr, u32) int
fn C.vmem_ContinueDebugEvent(u32, u32, u32) int
fn C.vmem_GetThreadContext(voidptr, voidptr) int
fn C.vmem_SetThreadContext(voidptr, voidptr) int

// DEBUG_EVENT prefix: code, pid, tid, then a union we do not parse
// (exception info is read back via thread CONTEXT instead).
struct DebugEventRaw {
mut:
	code u32
	pid  u32
	tid  u32
	pad  [200]u8
}

const win_thread_get_context = u32(0x0008)
const win_thread_set_context = u32(0x0010)
const win_ctx_debug_regs = u32(0x00100010)
const win_ctx_control = u32(0x00100001)
const win_dbg_continue = u32(0x00010002)

// context_alloc returns a 16-byte aligned CONTEXT buffer (x64 requirement).
fn context_alloc() (voidptr, voidptr) {
	raw := unsafe { malloc(1232 + 16) }
	aligned := voidptr((usize(raw) + 15) & ~usize(15))
	return raw, aligned
}

fn ctx_get_u64(ctx voidptr, off int) u64 {
	return unsafe { *(&u64(u8ptr_add(ctx, off))) }
}

fn ctx_set_u64(ctx voidptr, off int, v u64) {
	unsafe {
		*(&u64(u8ptr_add(ctx, off))) = v
	}
}

fn ctx_get_u32(ctx voidptr, off int) u32 {
	return unsafe { *(&u32(u8ptr_add(ctx, off))) }
}

fn ctx_set_u32(ctx voidptr, off int, v u32) {
	unsafe {
		*(&u32(u8ptr_add(ctx, off))) = v
	}
}

fn u8ptr_add(p voidptr, off int) voidptr {
	return unsafe { voidptr(usize(p) + usize(off)) }
}
