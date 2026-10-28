module sys

// Windows C interop declarations (AGENTS.md §3 grouped exception):
// fn C.* prototypes, struct layout mirrors, #include/#flag only.

#flag -lkernel32
#flag -lpsapi
#include <windows.h>
#insert "@VMODROOT/vmem/sys/win32_toolhelp.h"
#insert "@VMODROOT/vmem/sys/win32_dyn.h"

// handles
fn C.OpenProcess(u32, int, u32) voidptr
fn C.CloseHandle(voidptr) i32
fn C.GetCurrentProcessId() u32
fn C.GetCurrentProcess() voidptr

// memory
fn C.ReadProcessMemory(voidptr, voidptr, voidptr, usize, &usize) int
fn C.WriteProcessMemory(voidptr, voidptr, voidptr, usize, &usize) int
fn C.VirtualQueryEx(voidptr, voidptr, voidptr, usize) usize
fn C.VirtualAllocEx(voidptr, voidptr, usize, u32, u32) voidptr
fn C.VirtualFreeEx(voidptr, voidptr, usize, u32) int
fn C.VirtualProtectEx(voidptr, voidptr, usize, u32, &u32) int

// process / threads
// NOTE: signatures MUST match vlib decls where they exist
// (os/process_windows.c.v declares TerminateProcess bool, WaitForSingleObject i32).
fn C.TerminateProcess(voidptr, u32) bool
fn C.OpenThread(u32, int, u32) voidptr
fn C.SuspendThread(voidptr) u32
fn C.ResumeThread(voidptr) u32
fn C.CreateRemoteThread(voidptr, voidptr, usize, voidptr, voidptr, u32, &u32) voidptr
fn C.WaitForSingleObject(voidptr, i32) i32
fn C.GetExitCodeThread(voidptr, &u32) int
fn C.GetModuleHandleW(&u16) voidptr
fn C.GetModuleHandleA(&char) voidptr

// runtime-resolved (win32_dyn.h): absent from tcc's kernel32 import lib
fn C.vmem_GetProcessId(voidptr) u32
fn C.vmem_Module32FirstW(voidptr, voidptr) int
fn C.vmem_Module32NextW(voidptr, voidptr) int
fn C.vmem_Process32FirstW(voidptr, voidptr) int
fn C.vmem_Process32NextW(voidptr, voidptr) int

// toolhelp snapshots
fn C.CreateToolhelp32Snapshot(u32, u32) voidptr
fn C.Process32FirstW(voidptr, voidptr) int
fn C.Process32NextW(voidptr, voidptr) int
fn C.Module32FirstW(voidptr, voidptr) int
fn C.Module32NextW(voidptr, voidptr) int
fn C.Thread32First(voidptr, voidptr) int
fn C.Thread32Next(voidptr, voidptr) int

fn C.GetLastError() u32

// win32 struct layout mirrors (field order == C layout; snake_case V names,
// passed to C through voidptr). MEMORY_BASIC_INFORMATION (winnt.h).
struct MemBasicInfo {
mut:
	base_address       voidptr
	allocation_base    voidptr
	allocation_protect u32
	region_size        usize
	state              u32
	protect            u32
	type_              u32
}

// PROCESSENTRY32W (tlhelp32.h)
struct ProcessEntry32W {
mut:
	dw_size              u32
	cnt_usage            u32
	th32_process_id      u32
	th32_default_heap_id usize
	th32_module_id       u32
	cnt_threads          u32
	th32_parent_pid      u32
	pc_pri_class_base    i32
	dw_flags             u32
	sz_exe_file          [260]u16
}

// MODULEENTRY32W (tlhelp32.h)
struct ModuleEntry32W {
mut:
	dw_size         u32
	th32_module_id  u32
	th32_process_id u32
	glblcnt_usage   u32
	proccnt_usage   u32
	mod_base_addr   voidptr
	mod_base_size   u32
	h_module        voidptr
	sz_module       [256]u16
	sz_exe_path     [260]u16
}

// THREADENTRY32 (tlhelp32.h)
struct ThreadEntry32 {
mut:
	dw_size               u32
	cnt_usage             u32
	th32_thread_id        u32
	th32_owner_process_id u32
	tp_base_pri           i32
	tp_delta_pri          i32
	dw_flags              u32
}

// Win32 access/state/protect constants used by the sys layer.
pub const win_process_vm_read = u32(0x0010)
pub const win_process_vm_write = u32(0x0020)
pub const win_process_vm_operation = u32(0x0008)
pub const win_process_query_information = u32(0x0400)
pub const win_process_suspend_resume = u32(0x0800)
pub const win_process_terminate = u32(0x0001)
pub const win_process_create_thread = u32(0x0002)
pub const win_th32cs_snap_process = u32(0x0002)
pub const win_th32cs_snap_thread = u32(0x0004)
pub const win_th32cs_snap_module = u32(0x0008)
pub const win_th32cs_snap_module32 = u32(0x0010)
pub const win_mem_commit = u32(0x1000)
pub const win_mem_reserve = u32(0x2000)
pub const win_mem_free = u32(0x10000)
pub const win_mem_image = u32(0x1000000)
pub const win_mem_mapped = u32(0x40000)
pub const win_mem_private = u32(0x20000)
pub const win_thread_suspend_resume = u32(0x0002)
