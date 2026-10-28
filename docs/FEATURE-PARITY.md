# Vmem — feature parity (Cheat Engine / GameGuardian)

Status column reflects planning state until code lands. Phase references:
`docs/PLAN.md` §4. CE = Cheat Engine 7.x, GG = GameGuardian 101.x.

Legend: ✅ native feature · ⚠ partial / via scripting · ❌ absent · ✅ planned

## Process & memory map

| Feature | CE | GG | Vmem | Phase |
|---|---|---|---|---|
| Process list / attach / detach | ✅ | ✅ | ✅ | P0 |
| Module / library list | ✅ | ✅ | ✅ | P0 |
| Region map with perms | ✅ | ✅ | ✅ | P0 |
| Region filters: exe / writable / cow tri-state | ✅ | ⚠ ranges | ✅ | P1 |
| Region classes (java heap, c heap, stack, ashmem...) | ❌ | ✅ | ✅ | P0 (classes), P3 (Android map) |
| Hex dump to file | ✅ | ✅ | ✅ | P2 |
| Suspend / resume / kill process | ⚠ | ✅ | ✅ | P0 |

## Scanning

| Feature | CE | GG | Vmem | Phase |
|---|---|---|---|---|
| Exact / bigger / smaller / between | ✅ | ✅ | ✅ | P1 |
| Next scan: increased / decreased / changed / unchanged / same-as-first | ✅ | ✅ | ✅ | P1 |
| Unknown initial value | ✅ | ✅ (fuzzy) | ✅ | P2 |
| Fuzzy ops (fuzzy =/≠/>/< with delta) | ❌ | ✅ | ✅ | P2 |
| Types: byte..qword, float, double | ✅ | ✅ | ✅ | P1 |
| Strings: ascii / utf8 / utf16le / utf16be | ✅ | ✅ | ✅ | P2 |
| AoB pattern + wildcards + mask | ✅ | ✅ | ✅ | P2 |
| Group / multi-value scan (layouts) | ✅ grouped | ✅ `a;b::n` | ✅ | P2 |
| Address search + nibble mask | ❌ | ✅ | ✅ | P2 |
| XOR / encrypted value scan | ❌ | ✅ | ✅ | P2 |
| Auto / all-type sweep | ✅ | ✅ | ✅ | P2 |
| Fast scan (alignment / last digits) | ✅ | ⚠ | ✅ | P1 |
| Parallel multicore scan | ✅ | ✅ | ✅ | P1 |
| Result limit + address-range restrict | ✅ | ✅ | ✅ | P1 |
| Refine / "use selected as new results" | ✅ | ✅ | ✅ | P1 |
| Pause target while scanning | ✅ | ✅ | ✅ | P2 |
| Scan runs on-device (agent-side) | ❌ | ✅ (in-process) | ✅ (frida-style agent) | P3 |

## Results, editing, freeze

| Feature | CE | GG | Vmem | Phase |
|---|---|---|---|---|
| Edit single value | ✅ | ✅ | ✅ | P1 |
| Edit-all results | ✅ | ✅ | ✅ | P1 |
| Freeze (fixed rewrite) | ✅ | ✅ | ✅ | P4 |
| Freeze may-increase / may-decrease / in-range | ⚠ Lua | ✅ | ✅ | P4 |
| Saved lists (save/load) | ✅ tables | ✅ txt | ✅ (GG txt + CE .CT subset) | P4 |
| Stability tracking of addresses | ⚠ manual | ⚠ | ✅ (auto counter) | P1 |

## Pointer tools

| Feature | CE | GG | Vmem | Phase |
|---|---|---|---|---|
| Pointer scan (static anchor + offsets + depth) | ✅ | ⚠ maxOffset only | ✅ | P4 |
| Rescan filter (survive relocation) | ✅ | ❌ | ✅ | P4 |
| Pointer chain resolve / track | ✅ | ⚠ | ✅ | P4 |

## Code tools

| Feature | CE | GG | Vmem | Phase |
|---|---|---|---|---|
| AoB patch / injection templates | ✅ Auto Assembler | ✅ | ✅ | P5 |
| Remote alloc / code cave | ✅ | ✅ allocatePage | ✅ | P5 |
| Trampoline detour hooks | ✅ | ⚠ scripts | ✅ | P5 |
| DLL / so injection | ✅ | ❌ | ✅ | P5 |
| Shellcode execution | ✅ | ⚠ scripts | ✅ | P5 |
| Disassembler view | ✅ | ✅ disasm | 🎯 (post-0.1) | later |

## Debug & speed

| Feature | CE | GG | Vmem | Phase |
|---|---|---|---|---|
| Hardware breakpoints (DR0-3) | ✅ | ❌ | ✅ | P6 |
| Software breakpoints (INT3/BRK) | ✅ | ❌ | ✅ | P6 |
| Single-step + register r/w | ✅ | ❌ | ✅ | P6 |
| Watchpoints | ✅ | ❌ | ✅ | P6 |
| Speedhack (time scaling) | ✅ | ✅ | ✅ | P6 |
| Unrandomizer | ✅ | ❌ | 🎯 (post-0.1) | later |

## Structure & tooling

| Feature | CE | GG | Vmem | Phase |
|---|---|---|---|---|
| Structure dissector | ✅ | ❌ | ✅ | P8 |
| Offset finder between objects | ✅ | ❌ | ✅ | P8 |
| GUI | ✅ desktop | ✅ overlay | ✅ unique desktop (docs/GUI.md) | P7 |
| CLI/scriptable interface | ⚠ Lua | ✅ Lua | ✅ cli/ + V programs | P7 |
| Hotkeys | ✅ | ✅ | ✅ (GUI/CLI) | P7 |
| Remote device target (USB/LAN) | ⚠ Lua sockets | ❌ (self only) | ✅ frida-style agent | P3 |
| No-root operation | ❌ | ✅ virtual space | 🎯 gadget / run-as / virtual space | P8 |

## Explicit non-goals (D6)

| Feature | CE | GG | Vmem |
|---|---|---|---|
| Lua / JS scripting runtime | ✅ | ✅ | ❌ — write V programs against `import vmem` |
| Kernel driver / anti-anti-cheat | ✅ (dbk) | ✅ (randomize) | ❌ |
| Multiplayer cheat workflows | ⚠ | ⚠ | ❌ out of scope |
