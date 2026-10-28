# AGENTS.md — operating rules for the Vmem repository

Scope: every human and agent working in this repo. Facts about V and the
memory-tooling domain live in `SKILL.md`; design rationale lives in `docs/`.
This file is normative: MUST/SHOULD rules are enforced in review.

## 1. Commands

All commands run from repo root. Targets land in phase P0; do not invent
alternatives once they exist.

| Action | Command |
|---|---|
| Build library + CLI | `v .` (module consumers build via `import vmem`) |
| Run CLI | `v run cli <args>` (directory form: cli is a multi-file main) |
| Run GUI | `v run gui` (headless check: `v run gui -- --smoke 60`) |
| Run all tests | `v test .` |
| Single test file | `v test vmem/scan_first_test.v` |
| Format check | `v fmt -verify .` |
| Format fix | `v fmt -w .` |
| Static checks | `v vet .` |
| Cross build | `v -os linux .` / `v -os windows .` (macOS: see `docs/PLATFORM-API.md`) |
| Build device agent | `v -os linux -arch arm64 -cc <ndk-clang\|zig> agent/main.v` (static Linux ELF; P0/P3 validate exact toolchain) |
| Sync skill to agent dirs | `node mcp/sync-skills.mjs` (run after ANY `SKILL.md` edit) |
| Verify skill copies | `node mcp/sync-skills.mjs --check` |
| Doc queries | `vmem` MCP tools (`repo_context`, `search_docs`, `read_doc`, ...) — prefer over reading docs wholesale |

Test environment: integration tests spawn `tests/victim/victim.v` (a
deterministic process with known values). NEVER test against live games or
arbitrary third-party processes in CI.

## 2. Layering (hard rule)

```
gui/, cli/   ->  vmem (public API)          UI/UX only, zero OS calls
vmem/        ->  vmem/sys                   orchestration, scan engine, types
vmem/sys/    ->  local OS APIs (RPM/WPM, /proc, ptrace, mach)   ONLY place
vmem/sys/remote/ -> agent transport (ADB/TCP)                   ONLY place
agent/       ->  local OS APIs (same rules as vmem/sys)
```

- OS API calls MUST appear only in `vmem/sys/` and `agent/`. A `grep` for
  `C.ReadProcessMemory|process_vm_readv|ptrace|mach_vm_` outside those trees
  is a review failure.
- Transport/protocol code MUST appear only in `vmem/sys/remote/` (host side)
  and `agent/` (device side); the scan engine addresses both through the same
  backend interface.
- `gui/` and `cli/` MUST NOT import `vmem/sys` — only `vmem`.
- Every sys capability has a fake backend for tests (`vmem/sys/fake/`), wired
  through the same interface; engine tests run against the fake backend and a
  real `victim` process. Remote tests run against a fake transport plus an
  in-process agent instance.

## 3. File structure (hard rule)

**One function = one file.** File name is the function name in snake_case.

- Public API: `vmem/read_u32.v` contains exactly `pub fn read_u32(...)`.
  Test beside it: `vmem/read_u32_test.v`.
- Platform-variant bodies use V file suffixes on the SAME base name:
  `vmem/sys/read_u32_windows.c.v`, `vmem/sys/read_u32_linux.c.v`,
  `vmem/sys/read_u32_default.c.v`. A base file `read_u32.v` holds the shared
  signature/dispatch when bodies differ per OS. Android differences ride on
  `$if android` / `$if termux` blocks (V compiles these on the linux path).
- Declaration-only C interop files are the one grouped exception:
  `vmem/sys/decl_windows.c.v`, `vmem/sys/decl_linux.c.v`, ... hold
  `fn C.*` prototypes and `#include`/`#flag` lines for that OS.
- Types/enums/consts: `types.v`, `errors.v` (declarations only, no logic).
- Internal helpers: underscore prefix, one concern per file
  (`_match_eval.v`, `_pattern_parse.v`); keep under ~150 lines.
- No file mixes layers. No file both parses user input and performs syscalls.

## 4. API conventions

- Errors: public functions that can fail return `!T` or `!`; NEVER panic on
  environment conditions (process died, access denied, partial read).
  OS errors map to the taxonomy in `vmem/errors.v`; preserve the raw OS code
  and message in the error value.
- Naming: snake_case, verb_object (`read_u32`, `scan_first`, `enumerate_regions`).
  Units/encodings in names (`_bytes`, `_utf16le`). V types spelled as V types:
  `u8 u16 u32 u64 i8 i16 i32 i64 f32 f64`.
- Endianness: decode/encode is little-endian on all supported targets; any
  future exception MUST be a named parameter and a changelog entry.
- Mutable state: scan sessions, freeze lists, and pointer maps are structs
  passed as `mut`; document thread-safety per type (see `docs/ARCHITECTURE.md`).
- Allocation: hot paths (scan compare loops, region walking) MUST be
  zero-allocation after setup. Reuse buffers; chunked reads with caller-owned
  or session-owned scratch buffers. No string building in scan loops.

## 5. Testing rules

- Unit tests cover pure logic: value encode/decode, comparison/matcher rules,
  pattern parsers (`"48 8B ?? C3"`), table file formats (golden files).
- Integration tests cover the full stack against `tests/victim`: attach, region
  enumeration, typed r/w, first/next scans, freeze, pointer resolve.
- Every bug fix keeps a failing-before/passing-after test when reproducible.
- Memory-affecting changes get a `### Memory` changelog entry in the same PR
  (see `CHANGELOG.md` discipline).

## 6. Docs sync (same PR as the code change)

- New/changed public API → `docs/ARCHITECTURE.md` tree + `SKILL.md` recipes,
  then `node mcp/sync-skills.mjs` (skill copies for OMP/Claude/Codex).
- New doc file → register it in `mcp/registry.json` (search/read/resources).
- New capability or phase movement → `docs/FEATURE-PARITY.md` status column.
- New memory semantics → `CHANGELOG.md` `### Memory`.
- GUI-visible behavior → `docs/GUI.md`.

## 7. Safety scope

- Authorized targets only (own software, own games offline, CTF, labs).
- No kernel drivers, no anti-cheat evasion, no multiplayer cheat features.
- Code-injection features ship behind explicit API calls; defaults are
  read/scan only. Docs MUST state the authorization requirement.

## 8. Style

- `v fmt` output is canonical. No tabs-vs-spaces debates.
- Comments explain WHY and invariants, not what the line does.
- Prefer boring, explicit code over clever metaprogramming; V generics only
  where they remove real duplication (typed scan values).
