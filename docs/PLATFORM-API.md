# Vmem — platform API and permission models

Capability matrices the sys layer maps onto. Tier: 1 = full support target,
2 = best effort, 3 = where feasible.

## 1. Target tiers

| Target | Tier | Backend | Product path |
|---|---|---|---|
| Windows x64 | 1 | local (`vmem/sys/*_windows.c.v`) | library + CLI + GUI |
| Linux x64/arm64 | 1 | local (`*_linux.c.v`) | library + CLI + GUI |
| Android arm64 / arm / x86_64 | 1 | remote agent (`agent/` + `sys/remote/`) | host tool + device agent (frida-style) |
| macOS arm64/x64 | 2 | local (`*_darwin.c.v`) | library + CLI (GUI best effort) |
| FreeBSD/OpenBSD | 3 | local (`*_default.c.v` evolution) | library |

## 2. Desktop capability matrix

| Capability | Windows API | Linux API | macOS API |
|---|---|---|---|
| enumerate processes | Toolhelp32 `Process32First/Next` | `/proc/*/stat` + `comm` | `proc_listpids` / sysctl |
| attach / handle | `OpenProcess` (VM_READ/WRITE/OPERATION/QUERY/CREATE_THREAD) | pid + `/proc/<pid>/mem` fd; `process_vm_*` need ptrace-mode access | `task_for_pid` (mach port) |
| read | `ReadProcessMemory` | `process_vm_readv` (fast) / `pread` on `/proc/<pid>/mem` | `mach_vm_read_overwrite` |
| write | `WriteProcessMemory` | `process_vm_writev` / `pwrite` | `mach_vm_write` |
| regions | `VirtualQueryEx` (`MEMORY_BASIC_INFORMATION`: state/protect/type) | `/proc/<pid>/maps` (+`smaps` for RSS/class hints) | `mach_vm_region` (`vm_region_64`) |
| modules | Toolhelp32 `Module32*` / `EnumProcessModules` | maps rows with file paths + ELF parse for base/name | dyld image list / `mach_vm_region` walk |
| suspend / resume | `SuspendThread` / `ResumeThread` | `SIGSTOP`/`SIGCONT` (or ptrace attach stop) | `task_suspend` / `task_resume` |
| registers | `GetThreadContext` / `SetThreadContext` | `PTRACE_GETREGSET` / `SETREGSET` (NT_PRSTATUS) | `thread_get_state` / `set_state` |
| remote alloc | `VirtualAllocEx` / `VirtualFreeEx` | remote `mmap`/`munmap` via ptrace call-hijack | `mach_vm_allocate` |
| protect change | `VirtualProtectEx` | remote `mprotect` via ptrace | `mach_vm_protect` |
| thread enum | Toolhelp32 `Thread32*` | `/proc/<pid>/task` | `task_threads` |
| injection | `CreateRemoteThread` + `LoadLibraryA` (or APC) | ptrace + remote `dlopen` / `LD_PRELOAD` | thread hijack + `dlopen` (signed builds limited) |
| breakpoints | CONTEXT `Dr0-Dr3`, `RFlags` trap; `WaitForDebugEvent` optional | ptrace `POKEUSER` debug regs; `PTRACE_SINGLESTEP` | debug regs via `thread_set_state` |
| speedhook | IAT/inline hook `GetTickCount64`, `QueryPerformanceCounter`, `timeGetTime`, `Sleep` | GOT/PLT patch `clock_gettime`, `gettimeofday`, `nanosleep` | `DYLD_INTERPOSE` in-process only |

## 3. Permission models

| Platform | Requirement | Notes |
|---|---|---|
| Windows | same-or-lower integrity; `SeDebugPrivilege` for protected/system processes | protected processes (PPL) are out of reach by design (D6) |
| Linux | same UID, or root; `kernel.yama.ptrace_scope` ≤ 1 for non-ancestor ptrace | `/proc/<pid>/mem` writes follow ptrace access rules (kernel ≥ 3.10) |
| macOS | DevToolsSecurity enabled; `com.apple.security.cs.debugger` entitlement or SIP relaxed | tier 2; unsigned/ad-hoc build works on dev machines |
| Android | see §4 | SELinux + hidepid make cross-process reads impossible from the host shell |

## 4. Android — frida-style architecture

Host never touches Android target memory directly. The device agent performs
all reads/writes/scans on-device; the host drives it over the transport.

```
host: cli/ gui/ + vmem/ + vmem/sys/remote   ◄── framed RPC over TCP ──►   device: agent/ ──► target app
                                 ▲ adb forward tcp:W tcp:W  (USB)                 (ptrace/proc)
                                 └── raw TCP (network, LAN/VPN)
```

### 4.1 Agent deployment modes

| Mode | Privilege | How it works | Limitations |
|---|---|---|---|
| Root daemon (primary) | root (`su`/Magisk) | `vmemd` static Linux ELF started at boot/on demand; listens on 127.0.0.1:PORT; `adb forward` exposes to host — same model as frida-server | needs rooted device |
| In-process gadget | app UID | shared library loaded into target app (repackaged APK, or injected via any vector); same RPC over a local socket; like frida-gadget | needs a way to load the lib (repackage / virtual space) |
| `run-as` | app UID | agent binary run via `adb shell run-as <pkg>` | debuggable apps only |
| Virtual space | host app UID | agent + target run in one zygote-spawned namespace (GameGuardian no-root model) | fragile across OEMs; P8 evaluation |

### 4.2 On-device primitives (agent side)

| Op | Mechanism |
|---|---|
| attach | `PTRACE_ATTACH` / `PTRACE_SEIZE` (SEIZE preferred; no stop race) |
| read | `process_vm_readv` first; fallback `pread` on `/proc/<pid>/mem` |
| write | `process_vm_writev`; fallback `pwrite` |
| regions | `/proc/<pid>/maps` parse + class heuristic (java heap anon mappings, ashmem, code app/sys from pathname, stack) |
| modules | maps file-backed rows + ELF/so base resolution |
| scan | chunked compare in-agent (device-local speed, GameGuardian model); results streamed in batches; session state kept agent-side for next-scan |
| suspend | `SIGSTOP`/`PTRACE_INTERRUPT` |
| regs/step | `PTRACE_GETREGSET/SETREGSET`, `PTRACE_SINGLESTEP` |
| alloc | remote `mmap` via ptrace register hijack (`PTRACE_SETREGS` + cont to syscall) |

### 4.3 Why not host-side reads (explicit)

- SELinux: `untrusted_app` cannot read other domains' memory; even root-shell
  reads are policy-constrained without the right domain.
- `hidepid=2` on modern Android hides other users' `/proc` entries from shell.
- USB transports do not expose `/proc` at all. Conclusion: all target memory
  access flows through the agent (D1).

### 4.4 Protocol (summary; full spec in `vmem/sys/remote/protocol/`)

- Framing: `u32 length | u16 opcode | u16 flags | u64 request_id | payload` (LE).
- Handshake: version + capability negotiation (scan_offload, regs, alloc...).
- Scan: host sends `ScanPlan` (value codec + compare op + ranges + alignment);
  agent acks, then streams `ResultBatch` messages; `ScanNext` references the
  agent-side session id (like GG keeps results in-process).
- Timeouts + keepalive; every request gets exactly one terminal response.

## 5. Build matrix

| Artifact | Target | Toolchain | Command (planned) |
|---|---|---|---|
| vmem + cli + gui | Windows x64 | tcc/gcc/clang (MSVC not required) | `v .` / `v run gui/main.v` |
| vmem + cli | Linux x64/arm64 | gcc/clang | `v -os linux .` |
| `agent` (vmemd) | Android arm64 | zig cc or NDK clang, static | `v -os linux -arch arm64 -cc zig agent/main.v` |
| `agent` (vmemd) | Android arm / x86_64 | zig cc or NDK clang, static | same with `-arch arm64/x64` variants |
| macOS tier-2 | macOS arm64 | clang (on macOS host) | `v .` |

The agent is a plain static Linux ELF (frida-server precedent: no Android SDK,
no Termux, no JNI). Toolchain validation is P0/P3 acceptance work
(`docs/PLAN.md`); if zig cross flags misbehave, fallback is an NDK clang
container build.

## 6. CI matrix (planned)

| Job | Runs |
|---|---|
| windows-latest | `v fmt -verify .`, `v vet .`, `v test .` (victim integration) |
| ubuntu-latest | same |
| android-emulator (P3+) | agent build + device scan smoke against demo app |
| macos-latest (tier 2) | build + unit tests; integration best effort |
