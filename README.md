# Vmem

Cross-platform process memory manipulation library written in V. Target feature
surface: the union of Cheat Engine (desktop) and GameGuardian (Android) core
memory tooling — scanning, editing, freezing, pointer tools, code patching,
breakpoints, speedhack — as an importable library with CLI and GUI front ends.

**Status: v0.1.0 implemented** — P0–P8 core landed with tests (see [`CHANGELOG.md`](CHANGELOG.md)).

## Targets

| Target | Tier | Notes |
|---|---|---|
| Windows x64 | 1 | ReadProcessMemory/VirtualQueryEx family |
| Linux x64/arm64 | 1 | `/proc` + `process_vm_*` + ptrace |
| Android arm64/arm/x86_64 | 1 | Frida-style: host drives an on-device agent over ADB/TCP (root daemon, gadget, no-root paths); scans run agent-side |
| macOS arm64/x64 | 2 | `task_for_pid` gated by SIP/entitlement; best effort |
| FreeBSD/OpenBSD | 3 | falls out of the Linux `/proc`-less backend where feasible |

## Repository layout

| Path | Contents |
|---|---|
| `vmem/` | the library module (`import vmem`) |
| `vmem/sys/` | local OS shims, the only place OS APIs are called |
| `vmem/sys/remote/` | device-agent transport client (frida-style, over ADB/TCP) |
| `agent/` | on-device agent daemon (static Linux ELF, runs on Android like frida-server) |
| `cli/` | terminal front end (scan/freeze/maps/read/write) |
| `gui/` | desktop GUI (V UI widgets: buttons, dropdowns, listbox) |
| `gui-radar/` | gg-based radar visualizer (donut, sparklines) |
| `tests/` | integration tests + deterministic `victim` target process |
| `examples/` | runnable recipes |
| `docs/` | plan, architecture, platform API, feature parity, GUI design |
| `mcp/` | zero-dependency docs/conventions MCP server (`server.mjs`) + `registry.json` + `sync-skills.mjs` |
| `.omp/` `.claude/` `.codex/` | per-agent MCP registration and skill copies (generated) |

## Agent integration (OMP / Claude Code / Codex)

- **Skill**: canonical `SKILL.md` (repo root) is synced into `.omp/skills/vmem/`,
  `.claude/skills/vmem/`, `.codex/skills/vmem/` (and `~/.claude/skills/vmem/`,
  `~/.codex/skills/vmem/` for use from any project) via
  `node mcp/sync-skills.mjs`. After editing `SKILL.md`, run the sync
  (`--check` verifies drift).
- **MCP**: `mcp/server.mjs` (Node, zero deps) serves the docs as query tools
  (`repo_context`, `search_docs`, `read_doc`, `get_rules`, `get_recipe`,
  `get_vref`, `get_phase`, `get_platform`, `get_parity`, `check_structure`,
  `plan_files`) plus doc resources and a `feature-scaffold` prompt. Registered
  per agent: `.omp/mcp.json` (OMP), `.mcp.json` (Claude Code / portable),
  `.codex/config.toml` (Codex). Server script paths are machine-absolute —
  adjust if the repo moves.
- **Context**: `AGENTS.md` is the normative rules file (Codex + OMP + agents-md
  read it directly); `CLAUDE.md` points Claude Code to it.

## Documentation

- [`docs/PLAN.md`](docs/PLAN.md) — scope, workstreams, phases, risks
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — module map, file rules, threading
- [`docs/PLATFORM-API.md`](docs/PLATFORM-API.md) — per-OS capabilities and permission models
- [`docs/FEATURE-PARITY.md`](docs/FEATURE-PARITY.md) — Cheat Engine / GameGuardian matrix
- [`docs/GUI.md`](docs/GUI.md) — GUI concept and layout
- [`AGENTS.md`](AGENTS.md) — contributor/agent operating rules
- [`SKILL.md`](SKILL.md) — V language + memory-tooling domain reference
- [`CHANGELOG.md`](CHANGELOG.md) — memory changelog (every memory-affecting change)

## Intended use

Memory inspection and modification of processes you own or are explicitly
authorized to test (your own games in single-player/offline contexts, CTF
binaries, your own software, lab VMs). Not aimed at multiplayer cheating or
evading third-party anti-cheat; kernel drivers and anti-anti-cheat work are
out of scope by design.
