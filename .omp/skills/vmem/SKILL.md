---
name: vmem
description: V language and process-memory-manipulation domain reference (Cheat Engine / GameGuardian semantics, frida-style Android agent, Windows/Linux/macOS memory APIs) for the Vmem repo. Use when writing, reviewing, or planning Vmem code, scan engine work, or memory-tooling features.
---

# SKILL.md — V language + memory-tooling reference for Vmem

Read this before writing code in this repository. Part 1 is V language context
(V 0.5.x). Part 2 is the memory-manipulation domain model (Cheat Engine /
GameGuardian / frida concepts). Part 3 is the platform model. Part 4 is
conventions (normative rules are in `AGENTS.md`). Part 5 is recipes.

## 1. V language context

### 1.1 Syntax essentials

```v
module vmem

fn read_u32(pid int, addr u64) !u32 {        // !T = result type (errors, no exceptions)
	mut buf := []u8{len: 4}                   // := declares, = assigns; mut for mutable
	n := read_bytes(pid, addr, mut buf)!      // ! propagates the error to the caller
	if n != 4 {
		return error('short read: ${n}/4')    // interpolation: ${expr} or $ident
	}
	return u32(buf[0]) | (u32(buf[1]) << 8)   // explicit LE decode; see AGENTS.md §4
}
```

- Visibility: first letter uppercase = public (`pub fn` also spelled `pub fn Read...`
  never; V style is snake_case with `pub`). `pub struct`, `pub enum`.
- Control: `if` / `match` (exhaustive over enums) / `for i in 0 .. n` /
  `for cond` / `for k, v in mp` / `for item in arr`. No `while` keyword.
- Types: `u8 u16 u32 u64 i8 i16 i32 i64 f32 f64 usize isize`, `bool`, `string`,
  `rune` (codepoint), `[]T` (arrays), `map[K]V`, `[N]T` (fixed arrays),
  `voidptr`, `&T` (references/pointers), `charptr`, `size_t`.
- Structs: fields may carry defaults; `struct C.Foo {}` declares an opaque C type.
  `@[typedef]` attribute for C typedefs. `enum` values referenced as `.member`.
- `defer`, `or { ... }` blocks for optionals/results, `return err` to propagate,
  `none` for optionals, `panic()` only for programmer errors (never for OS errors —
  see AGENTS.md §4).

### 1.2 Errors

No exceptions. Fallible functions return `!T` (or bare `!` for `void`). The error
value implements `IError` (`msg()`, `code()`). Custom error types live in
`vmem/errors.v` and carry the raw OS error code. Callers handle with
`x := f() or { return err }` or `f()!` to propagate.

### 1.3 Modules, files, platform splits

- One module per directory; `import os`, `import sync`, selective import
  `import sync { Mutex }`, alias `import sync as s`.
- Project-local module: this repo's library is the `vmem/` directory (`import vmem`).
- **File name suffixes select platform**: `foo_windows.v`, `foo_linux.v`,
  `foo_darwin.v`, `foo_default.v` (fallback), `foo_nix.v`. The `.c.v` suffix
  marks files compiled only for the C backend (C interop lives there).
- Compile-time branches: `$if windows {}`, `$if linux {}`, `$if android {}`,
  `$if termux {}`, `$if x64 {}`, `$if arm64 {}`. Verified present in V's own
  vlib (`$if android && !termux` appears in `builtin/`).
- File-per-function convention and the grouped `decl_<os>.c.v` exception:
  `AGENTS.md` §3.

### 1.4 C interop and unsafe

```v
#include <windows.h>
#flag -lkernel32

fn C.OpenProcess(u32, bool, u32) voidptr
struct C.PROCESS_INFORMATION {}

x := unsafe { *(&u32(ptr)) }    // deref, casts, pointer math require unsafe
sz := sizeof(u64)               // __offsetof(Type, field) also available
cstr := c'kernel32'             // C string literal
```

- `#include` / `#flag` / `#pkgconfig` directives, `fn C.Name(...)` prototypes and
  `struct C.X {}` declarations live ONLY in `vmem/sys/decl_<os>.c.v` (AGENTS.md §3).
- V memory: Boehm GC by default; `unsafe { malloc(n) }` / `unsafe { free(p) }` for
  raw buffers. Scan hot paths MUST NOT allocate per comparison (AGENTS.md §4):
  preallocate scratch buffers per worker/session.

### 1.5 Concurrency (what exists in vlib)

- `spawn f()` launches a thread; join via the returned handle.
- `sync` module: `sync.Mutex`, `sync.RwMutex`, `sync.WaitGroup`, `sync.Semaphore`,
  `sync.Cond`, `sync.Once`, `sync.Channel` (`sync.new_channel[T](n)`,
  `channel_select(...)`), `sync/threads` (thread pool), `sync/pool` (job pool),
  `sync/stdatomic` (atomics).
- `runtime.nr_cpus()` sizes scan worker pools.
- `os.Process` (vlib `os/process.v`): spawn/kill/wait child processes — used for
  the test `victim`. `os/signal` for signal handling in the agent daemon.

### 1.6 Build, test, cross-compile

| Action | Command |
|---|---|
| Build | `v .` / `v -prod .` / `v -shared vmem/` |
| Test | `v test .`; tests are `*_test.v` with `fn test_xxx()` + `assert` |
| Format / lint | `v fmt -w .` / `v vet .` |
| Cross compile | `v -os windows .`, `v -os linux .`, `v -os freebsd .` |
| Pick C compiler | `-cc tcc|gcc|clang|zig` (zig/NDK-clang for Android-targeted ELFs) |
| Defines | `-d ident` visible as `$if ident` |

Windows/Linux/FreeBSD are V's first-class cross targets. macOS cross needs a
Darwin toolchain (osxcross/zig). The Android product path is NOT a Termux CLI:
it is the frida-style on-device agent (Part 3), which is a static Linux ELF —
buildable with `v -os linux -arch arm64 -cc <zig|ndk-clang>` (toolchain choice
validated in P0/P3, see docs/PLAN.md).

## 2. Memory-tooling domain model

### 2.1 Value types (Cheat Engine / GameGuardian union)

| Kind | Size | Notes |
|---|---|---|
| byte / word / dword / qword | 1/2/4/8 | signed or unsigned view of the same bytes |
| float / double | 4/8 | IEEE 754 |
| string | var | encodings: ascii, utf8, utf16le, utf16be; terminator optional |
| aob (array of bytes) | var | pattern with `??` wildcards + mask |
| xor (encrypted) | 1-8 | GameGuardian `TYPE_XOR`; scan for encoded value |
| auto | 1-8 | sweep all scalar sizes (GG `TYPE_AUTO`, CE "All") |

All numeric decode/encode is little-endian (all supported targets are LE).

### 2.2 Scan lifecycle and compare ops

First scan ops: `exact`, `range(a..b)`, `gt`, `lt`, `unknown_initial`.
Next scan ops (compare against saved previous value): `exact`, `range`, `gt`,
`lt`, `increased`, `increased_by`, `decreased`, `decreased_by`, `changed`,
`unchanged`, `same_as_first`. Fuzzy ops (GG, unknown initial): `fuzzy_equal`,
`fuzzy_not_equal`, `fuzzy_greater`, `fuzzy_less`.

### 2.3 Pattern languages

| Syntax | Origin | Example | Meaning |
|---|---|---|---|
| AOB | CE | `48 8B ?? C3` | byte pattern, `??` = any byte |
| group | CE | `4:75 4:* 4:100` | typed values in layout, `*` = any |
| group+gap | GG | `6~7;7;1~2;0;0::29` | values/ranges `;`-separated, `::29` group size hint |
| range value | GG | `10~20`, `5Ch;0~~0` | value ranges; `0~~0` = any |
| address+mask | GG | `0B?0` @ mask `0xFFF` | address nibble search with mask |
| string | both | `"hp=100"` (utf16le etc.) | text with encoding |

### 2.4 Regions

Filters (CE): tri-state executable, writable, copy-on-write; module scope;
explicit start/stop range; fast-scan alignment (default 4) or last-N-digits.
Region classes (GG `REGION_*`): `code_app`, `code_sys`, `java_heap`, `c_heap`,
`c_alloc`, `c_bss`, `c_data`, `stack`, `anonymous`, `ashmem`, `video`, `other`,
`bad`, `ppsspp`. Vmem keeps both: raw perms bits + derived class.

### 2.5 Results, freeze, pointers

- Results: address + current value + previous value + type + stability counter;
  refine (re-filter by new criteria against the same list), edit-all, subsets.
- Freeze modes (GG `FREEZE_*`): `normal` (rewrite fixed value), `may_increase`,
  `may_decrease`, `in_range(from,to)`. Implemented as a periodic re-write ticker
  (default ~10 Hz, per-entry override).
- Pointer chains: `base(module+offset) -> +off1 -> +off2 ... -> target`.
  Pointer scan: find static anchor; defaults: max offset 2048 bytes, max depth
  5; rescan filter keeps only paths surviving a relocation (CE workflow:
  scan -> relocate -> rescan -> repeat). Static = inside a loaded module image,
  shown as `module+offset` (CE green addresses).

### 2.6 Code tools (advanced)

- AOB injection: pattern-scan then patch (e.g. NOP a check, force a jump).
- Remote alloc + code cave; trampoline detour hook (save stolen bytes, jmp back).
- DLL/so injection: `CreateRemoteThread` + `LoadLibrary` (Windows);
  `ptrace` + remote `dlopen` call or `LD_PRELOAD` (Linux/Android).
- Breakpoints: hardware DR0-DR3 (no code patch) via thread context; software
  `INT3`/`BRK` with original-byte save. Single-step + register read/write.
- Speedhack: time-source scaling — hook `GetTickCount64`/`QueryPerformanceCounter`
  /`Sleep` (Windows) or `clock_gettime`/`gettimeofday` (Linux/Android, via
  GOT/PLT patch in target) and scale deltas.

## 3. Platform model

### 3.1 Desktop (local backend, in `vmem/sys/`)

| Capability | Windows | Linux | macOS (tier 2) |
|---|---|---|---|
| attach | `OpenProcess` | pid + `ptrace`/`/proc/<pid>/mem` | `task_for_pid` (SIP/entitlement gated) |
| read | `ReadProcessMemory` | `process_vm_readv` / `pread` on `/proc/pid/mem` | `mach_vm_read_overwrite` |
| write | `WriteProcessMemory` | `process_vm_writev` / `pwrite` | `mach_vm_write` |
| regions | `VirtualQueryEx` | `/proc/<pid>/maps` (+smaps) | `mach_vm_region` |
| modules | Toolhelp32 / `EnumProcessModules` | maps file-backed rows | dyld image list |
| suspend/regs | `SuspendThread`, `Get/SetThreadContext` | `SIGSTOP`, `PTRACE_GETREGSET/SETREGSET` | `task_suspend`, `thread_get_state` |
| remote alloc | `VirtualAllocEx` | remote `mmap` via ptrace hijack | `mach_vm_allocate` |

### 3.2 Android (remote agent — frida-style, NOT Termux)

```
host (Windows/Linux/macOS)                     device (Android)
┌──────────────────────────┐    ADB/TCP     ┌────────────────────────────┐
│ cli/ + gui/              │  adb forward   │ agent/  (static Linux ELF, │
│ vmem/  ── scan engine ── │◄──────────────►│  root daemon like          │
│ vmem/sys/remote/ client  │  framed RPC +  │  frida-server, or in-      │
└──────────────────────────┘  bulk streams  │  process gadget)           │
                                            │   └─ ptrace /proc/pid/mem  │
                                            │      onto target app       │
                                            └────────────────────────────┘
```

- **Host side**: unchanged — `vmem` talks to a `MemoryBackend`; the remote
  backend streams operations over the transport. Scan plans can run agent-side
  (chunked, session-stateful like GameGuardian) or host-side over bulk reads.
- **Agent modes**:
  1. Root daemon (primary): started via `su`/Magisk, listens on localhost TCP,
     forwards with `adb forward tcp:<port> tcp:<port>` — same ops model as
     frida-server. Attach via ptrace; reads via `process_vm_readv` or
     `/proc/<pid>/mem`.
  2. In-process gadget (no root): a shared library loaded into the target app
     (repackaged APK / injected / virtual-space like GameGuardian no-root);
     exposes the same RPC in-process over a local socket.
  3. `run-as` mode (debuggable apps only): agent runs in the app's UID via ADB.
- **Protocol**: custom binary framed RPC (opcode, request id, length, payload;
  little-endian), bulk result streaming for scans; versioned handshake. Detail
  in `docs/ARCHITECTURE.md`.
- SELinux notes: root-daemon runs as `u:r:su`/magisk domain → ptrace allowed;
  `untrusted_app` cross-domain `process_vm_readv` is blocked → all reads go
  through the privileged agent. hidepid=2 hides `/proc` from shell → agent must
  run as root. These are the reasons host-side reading of Android targets is
  not a supported path.

## 4. Conventions (pointer)

Normative: `AGENTS.md` — layering (OS calls only in `vmem/sys/` + `agent/`),
one-function-per-file, error taxonomy usage, allocation rules, changelog
discipline (every memory-affecting change → `CHANGELOG.md` `### Memory`).

## 5. Recipes

### 5.1 Add a typed read (e.g. `read_f32`)

1. `vmem/read_f32.v` — `pub fn read_f32(pid int, addr u64) !f32`, decodes LE via
   `read_bytes`.
2. If the OS has a faster bulk path: `vmem/sys/read_f32_windows.c.v`,
   `vmem/sys/read_f32_linux.c.v`, `vmem/sys/read_f32_default.c.v` (+ prototypes
   in `decl_<os>.c.v`).
3. Fake backend entry `vmem/sys/fake/` for engine tests.
4. `vmem/read_f32_test.v` + victim fixture usage.
5. `CHANGELOG.md` `### Memory` entry if decode semantics are new.

### 5.2 Add a scan compare op

1. `types.v`: enum member in `CompareOp`.
2. `_match_eval.v`: the comparison (pure function, no allocation).
3. CLI/GUI surface + `docs/FEATURE-PARITY.md` row + `CHANGELOG.md` entry.

### 5.3 Add an agent RPC op (Android)

1. `vmem/sys/remote/protocol/opcodes.v`: opcode + wire encode/decode (one file
   per message type).
2. Host: `vmem/sys/remote/<fn>.v` (one function per file).
3. Agent: `agent/handlers/<fn>.v` (one function per file).
4. Tests: fake transport round-trip + in-process agent integration.
5. `docs/PLATFORM-API.md` capability matrix update.

### 5.4 Add an OS backend

1. `vmem/sys/decl_<os>.c.v` — `#include`/`#flag`/`fn C.*` prototypes only.
2. Per-function impl files `vmem/sys/<fn>_<os>.c.v` for every capability the OS
   provides natively; `_default.c.v` returns `unsupported` errors elsewhere.
3. Backend selection lives in `vmem/sys/backend_<os>.c.v` (one file per OS).
4. Update `docs/PLATFORM-API.md` and the fake backend.
