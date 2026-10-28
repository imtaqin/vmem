# Vmem — master plan

Status: implemented (v0.1.0) — phases P0–P8 core complete; device-only work (gadget/no-root, macOS validation) remains as documented. Goal: a cross-platform process memory
manipulation library in V with the union feature surface of Cheat Engine and
GameGuardian, Frida-style Android support, CLI + GUI front ends.

## 1. Vision

`import vmem` gives a program the ability to attach to a process (local OS or
remote Android device), enumerate its memory, scan for values with CE/GG-class
semantics, edit and freeze results, resolve pointer chains, and perform code
tooling (patch, hook, inject, breakpoints, speedhack). Ship as:

1. **Library** (`vmem/`) — the product. Everything else is a client of it.
2. **Device agent** (`agent/`) — frida-server-class daemon for Android;
   static Linux ELF, root daemon or in-process gadget.
3. **CLI** (`cli/`) — scriptable terminal front end.
4. **GUI** (`gui/`) — desktop front end with a unique layout (docs/GUI.md).

Principles: correctness > performance > ergonomics; boring explicit design;
zero-allocation hot paths; every memory-affecting change lands with a
`CHANGELOG.md` entry; authorized targets only (README "Intended use").

## 2. Scope

### In

- Process lifecycle: enumerate (name/pid/path), attach, detach, suspend/resume,
  kill. Module/image enumeration.
- Region maps: raw perms + CE-style filters (executable/writable/cow, module
  scope, range) + GG-style classes (java_heap, c_heap, stack, ...).
- Typed read/write: all scalar sizes, strings (ascii/utf8/utf16le/utf16be),
  byte arrays, bulk chunked I/O, memory dump to file.
- Scan engine: first/next scan ops (exact, range, gt/lt, increased/decreased by,
  changed/unchanged, same-as-first), unknown-initial, fuzzy ops, AOB+mask,
  group/multi-value patterns, string encodings, XOR/encrypted, address+mask,
  auto-type sweep, fast-scan alignment, result limits, parallel workers,
  agent-side scan offload.
- Results: refine, edit-all, subsets, stability tracking, save/load lists
  (GG text format; CE `.CT` subset import).
- Freeze: normal / may_increase / may_decrease / in_range, per-entry rate.
- Pointer tools: pointer scan (static detection, offset bounds, depth),
  rescan filter (relocation survival), chain resolve.
- Code tools: AOB patch/injection templates, remote alloc + code cave,
  trampoline hooks, DLL/so injection, shellcode exec.
- Debug: hardware breakpoints (DR0-3), software breakpoints, single-step,
  register read/write, watchpoints.
- Speedhack: timer scaling hooks per OS.
- Structure dissect: offset finder between two objects, field type inference.
- Android: full support via host↔agent (frida-style) — root daemon, gadget,
  run-as modes; agent-side scanning.
- GUI: unique layout (memory-map donut, sparklines, scan timeline), desktop.

### Out (explicit non-goals)

- Kernel drivers, anti-cheat evasion, multiplayer cheating tooling.
- JavaScript/Lua scripting runtime (frida-style JS instrumentation) — the
  scripting surface is V itself (write small V programs against the library).
  Revisit only if demanded.
- iOS (mach layer is reusable in principle; not planned).
- Rewriting game binaries on disk (patching the running process only).

## 3. Workstreams

| WS | Content | Depends on |
|---|---|---|
| WS1 Core I/O | types, errors, sys seam + fake backend, process/regions/modules, typed r/w, dump | — |
| WS2 Scan engine | matcher ops, patterns, region filters, parallel workers, results mgmt, refine | WS1 |
| WS3 Pointer & tables | pointer scan/resolve, rescan filter, freeze manager, save/load lists | WS2 |
| WS4 Code tools | remote alloc, patch/injection, trampoline hooks, shellcode | WS1 |
| WS5 Debug & speed | HW/SW breakpoints, single-step, regs, watchpoints, speedhack hooks | WS4 |
| WS6 Android platform | framed RPC protocol, agent daemon, ADB/TCP transport, scan offload, gadget, no-root modes | WS1, WS2 |
| WS7 GUI | custom gg/sokol UI kit, radar layout, panels | WS2 (v1), WS3/WS6 (full) |
| WS8 CLI | commands for all library surfaces, JSON output mode | WS1-WS3 |
| WS9 Docs & QA | docs sync, parity matrix, changelog, release engineering | continuous |

## 4. Phases

Each phase lists acceptance criteria (AC) — the phase is done when they pass
on the stated targets.

### P0 — Foundation (WS1)
- Repo skeleton per `docs/ARCHITECTURE.md`; `v fmt -verify .`, `v vet .`,
  `v test .` green.
- `types.v`, `errors.v`; `MemoryBackend` interface; fake backend.
- Windows + Linux local backends: open/detach, region enum, module enum,
  read/write bytes.
- `tests/victim` deterministic target process + integration harness.
- **AC**: attach to victim on Windows and Linux, read back a planted u32.

### P1 — Scan engine v1 (WS2)
- Scalar value types, first/next scan ops, region filters, alignment fast scan,
  parallel workers (`sync` pool/atomics, `runtime.nr_cpus()`).
- Results list with previous-value tracking; edit-all; refine.
- **AC**: exact/ranged/increased/decreased scans find planted victim values;
  deterministic result sets; no allocations in compare loop (checked via
  session buffer accounting).

### P2 — Advanced scan (WS2)
- AOB+mask, group patterns (CE + GG syntax), fuzzy/unknown-initial, string
  encodings, XOR/encrypted, address+mask, auto sweep, result limits, dump.
- **AC**: golden-file pattern tests pass; AOB finds planted byte patterns.

### P3 — Android agent v1 (WS6)
- Wire protocol v1 (framed binary RPC, versioned handshake, bulk scan
  streaming) + agent core: attach, r/w, regions, modules, scan offload with
  session state.
- Root-daemon deployment path (`su`/Magisk + `adb forward`).
- Build: static Linux ELF arm64/arm/x86_64 via zig/NDK-clang (validated here).
- **AC**: host CLI scans a demo Android app on a real/emulated device over
  `adb forward`; agent-side scan results match host-side scan over bulk reads.

### P4 — Pointer, freeze, tables (WS3)
- Pointer scan + rescan filter + chain resolve; freeze manager; GG text list
  save/load; CE `.CT` subset import.
- **AC**: planted pointer chain in victim resolves after relocation; freeze
  holds a value under victim mutation at 10 Hz.

### P5 — Code tools (WS4)
- Remote alloc/code cave, AOB patch + injection templates, trampoline hook,
  DLL/so injection, shellcode exec. Same APIs work via agent on Android (P5b).
- **AC**: hook a victim function, observe redirected behavior; restore patch
  cleanly (byte-exact revert).

### P6 — Debug & speedhack (WS5)
- HW breakpoints (DR0-3 via thread context), SW breakpoints, single-step,
  registers, watchpoints; speedhack via timer hook templates per OS.
- **AC**: breakpoint on victim write hits with correct register state;
  speedhack scales victim timer reads 0.1x-10x.

### P7 — GUI v1 + CLI polish (WS7, WS8)
- Custom `gg`/sokol UI kit; radar layout (docs/GUI.md): region-map donut,
  virtualized results table with sparklines, scan timeline, inspector,
  command palette. CLI JSON mode complete.
- **AC**: GUI completes the P1/P2 scan workflow end-to-end against victim;
  60 fps table scrolling with 1M results (virtualized).

### P8 — Dissect, no-root paths, macOS, release (WS6, WS9)
- Structure dissect + offset finder; Android gadget + run-as + virtual-space
  no-root paths; macOS tier-2 backend validation; semver 0.1.0 release.
- **AC**: dissect finds planted struct offsets in victim; gadget mode scans a
  debuggable demo app without root.

## 5. Testing strategy

- Unit: pure logic (decode/encode, matchers, pattern parsers, table formats).
- Integration: against `tests/victim` (planted scalars, strings, AoB patterns,
  pointer chain, mutable loop for freeze tests). Runs on Windows + Linux in CI;
  Android runs in an emulator job (P3+).
- Remote: fake transport (deterministic) + in-process agent (real protocol
  loopback) + on-device smoke per release.
- Perf guards: scan throughput benchmark (MB/s per core) tracked per phase;
  allocation counter assertion in scan loop tests.

## 6. Risk register

| Risk | Impact | Mitigation |
|---|---|---|
| Android SELinux/hidepid blocks cross-process reads | High | Root-daemon model (like frida-server); all device reads through agent; document per-mode limits |
| V cross-compile to Android ELF unproven (zig/NDK clang) | Med | Validate in P0/P3; fallback: build agent inside an NDK container; agent is plain Linux ELF — no Android SDK needed |
| ptrace attach races / app protections | Med | Document; retries on attach; anti-anti-cheat explicitly out of scope |
| macOS `task_for_pid` gated by SIP/entitlement | Low | Tier-2; best effort, documented |
| GUI scope creep | Med | UI kit frozen after P7 v1; feature freeze to library parity |
| Scan perf below CE on huge address spaces | Med | Agent-side scan (device-local speed), chunked parallel workers, fast-scan alignment |

## 7. Open questions (defaults chosen; say if wrong)

| Question | Default |
|---|---|
| License | MIT |
| Min Android version | 7.0 (arm64 primary; arm/x86_64 secondary) |
| Protocol encoding | custom binary framed RPC (not msgpack) |
| GUI on Android | not in v1 (CLI + agent); overlay UI evaluated in P8+ |
| Scripting runtime (JS/Lua) | out of scope (V programs are the scripts) |

## 8. Decision log (moved: see docs/ARCHITECTURE.md §7)
