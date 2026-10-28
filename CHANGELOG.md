# Vmem Memory Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning: [Semantic Versioning](https://semver.org/).

**Memory discipline:** every change that affects memory semantics MUST be recorded
under a `### Memory` subsection of the release it lands in. Memory semantics means:
read/write behavior, value encode/decode, scan matching rules, region filtering,
freeze behavior, pointer resolution, patch/hook effects on target processes.
Purely cosmetic, docs-only, or internal refactors go under the normal subsections.

## [Unreleased]

### Added
- GUI rebuilt on V (ui module): clickable buttons, textboxes, dropdowns and
  results listbox (attach/scan/refine/freeze/dump all mouse-driven). The
  gg-based radar visualizer moved to `gui-radar/`.
- Known V-UI quirks found and avoided: non-ASCII glyphs (em-dash) in widget
  text crash its font loader silently; native widget updates before `ui.run`
  crash silently. GUI strings are ASCII-only; demo mode only prefills fields.

## [0.1.0] — 2026-10-28

### Added
- Library `vmem`: typed read/write (byte..qword, f32/f64, LE), region/module/
  process enumeration, scan engine, freeze manager, pointer tools, code tools
  (alloc/patch/hook/shellcode/DLL inject), debug layer (HW breakpoints,
  single-step, registers), speedhack, structure dissect, session save/load.
- Device agent `agent/` (vmemd): frida-style host↔agent over framed TCP with
  agent-side scan offload; in-process loopback verified.
- CLI `cli/`: ps, maps, mods, read, write, scan (state-file sessions),
  results, freeze, ptr, dump.
- GUI `gui/`: "Radar" layout on gg — memory-map donut, sparkline result rows,
  scan timeline, command palette; headless `--smoke` verification mode.
- Test suite: 16 files — unit (codec, matchers, patterns, freeze, pointers,
  tables), fake-backend scans, and victim integration (attach, r/w, scans,
  freeze, pointers, dissect, inject, watchpoint, speedhack, remote loopback).
- Agent tooling: docs/conventions MCP server (`mcp/`), skill packaging synced
  to OMP/Claude/Codex (`mcp/sync-skills.mjs`).

### Memory
- Decode/encode is little-endian on all targets; scalar scan/edit widths are
  byte=1 word=2 dword=4 qword=8 float=4 double=8.
- Integer scan comparisons use sign-extended i64 (byte/word/dword exact;
  qword values above i64 max are a documented v1 limitation). Float/double
  compare as f64; float equality is bitwise-exact.
- First scan ops use the operand only; delta ops compare against the bytes
  saved at the previous scan; `same_as_first` compares against the first-scan
  bytes; `unknown` keeps every in-scope address.
- Fuzzy ops treat `value` as the delta: `fuzzy_eq |cur-prev|<=delta`,
  `fuzzy_ne |cur-prev|>delta`, `fuzzy_gt cur>prev+delta`,
  `fuzzy_lt cur<prev-delta`.
- `mask` applies to eq/ne on scalar kinds: `(cur^value)&mask == 0`.
  `xor_key` de-encodes scalar values before comparison (`cur^xor_key`).
- Pattern kinds (aob/text/group) match through per-byte masks (0xFF exact,
  0x00 wildcard) plus optional range cells; their scan width is the pattern
  length; allowed ops are eq/ne/changed/unchanged/unknown.
- Group patterns: CE `T:V` cells (1/2/4/8/f/d, `*`, `a~b`) and GG `v;v::N`
  cells (uniform width, `::N` front-packs and pads with trailing wildcards).
- ScanFilter start/end clip the scanned range inside selected regions;
  classes is a RegionClass bitmask; prot_require/prot_reject filter bits.
- Scan reads are chunked through one reusable window (64 KiB) with request
  size backoff on failure (short mappings and region ends); unreadable pages
  are skipped by 4 KiB steps. The compare loop allocates only when result
  arrays grow.
- Freeze modes: `.normal` rewrites every tick; `.may_increase` writes only
  when the value dropped below the point; `.may_decrease` only when it rose
  above; `.in_range` clamps into [from, to].
- Pointer paths: `resolve_pointer` walks `cur = *cur + offset` per offset,
  deepest-first; `pointer_scan` emits a path per hit at every depth;
  `rescan_pointers` keeps only paths resolving to the new target.
- `protect_memory` is unit-symmetric: protection is expressed in
  `prot_read/write/exec/cow` bits in AND out (restoring a previous
  protection round-trips exactly).
- Trampoline hooks relocate `stolen_len` bytes (caller ensures instruction
  boundaries) and `remove_hook` restores the original bytes byte-exactly.
  Relocated prologues that are not position-independent must not be executed
  from the trampoline (GetTickCount: use the cave/exit-code path instead).
- Speedhack: GetTickCount is detoured to a cave returning a host-driven
  virtual clock; `speedhack_tick` advances it by `real_elapsed * factor`;
  only deltas are meaningful (the virtual epoch is arbitrary).
- Agent scan offload executes the same ScanPlan/matcher semantics
  agent-side; loopback tests assert offload results equal host-side scans
  over bulk reads.
- DLL injection runs `LoadLibraryW` with a UTF-16LE remote path buffer and
  returns the produced module handle; `run_shellcode` executes RWX pages as
  remote threads and returns their exit codes.
- Windows debug layer: hardware breakpoints live in DR0-DR3 per thread
  (DR7 local-enable + RWn/LENn encodings); watchpoint hits report DR6 slot
  bits; single-step reports DR6.BS; `DebugActiveProcess` must precede
  `DebugSetProcessKillOnExit` (kill-on-exit disabled: targets survive
  detach).
