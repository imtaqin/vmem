# Vmem GUI — "Radar" layout

Front end for the library on desktop (Windows/Linux, macOS best effort). Rule:
GUI code calls `vmem` public API only (AGENTS.md §2). Android gets CLI + agent
in v1; an on-device overlay is evaluated in P8+ (see docs/PLAN.md).

## 1. Design language

- Dark-first theme, mono numerals (all addresses/values), 4px spacing grid.
- One idea per region; live data glows (subtle), stale data dims.
- Keyboard-first: every action reachable from the command palette (Ctrl+K).
- No skeuomorphism; flat panels with hairline borders; accent used only for
  "live" states (scan running, value changed, frozen).

Theme tokens (mapped to reader/system theme variables):

| Token | Use |
|---|---|
| `--bg` | app background |
| `--surface` | panels, rows |
| `--fg` | primary text |
| `--muted` | secondary text, axes |
| `--border` | hairlines, table grid |
| `--accent` | live state, selection |
| `--success` / `--warning` / `--error` | frozen / unstable / dead addresses |
| `--c1..--c6` | region-class series in the donut and sparklines |

## 2. Layout

```svg
<svg viewBox="0 0 960 560" font-family="ui-monospace, monospace" font-size="12">
  <!-- outer frame -->
  <rect x="8" y="8" width="944" height="544" rx="8" fill="none" stroke="var(--border)"/>
  <!-- left rail -->
  <rect x="8" y="8" width="56" height="544" rx="8" fill="none" stroke="var(--border)"/>
  <circle cx="36" cy="44" r="10" fill="none" stroke="var(--accent)"/>
  <text x="36" y="80" text-anchor="middle" fill="var(--muted)">proc</text>
  <text x="36" y="112" text-anchor="middle" fill="var(--muted)">scan</text>
  <text x="36" y="144" text-anchor="middle" fill="var(--fg)">ptr</text>
  <text x="36" y="176" text-anchor="middle" fill="var(--muted)">code</text>
  <text x="36" y="208" text-anchor="middle" fill="var(--muted)">dbg</text>
  <!-- top bar -->
  <rect x="64" y="8" width="888" height="40" fill="none" stroke="var(--border)"/>
  <rect x="80" y="18" width="150" height="20" rx="10" fill="none" stroke="var(--accent)"/>
  <text x="155" y="32" text-anchor="middle" fill="var(--accent)">victim.exe  pid 4242</text>
  <rect x="248" y="18" width="64" height="20" rx="10" fill="none" stroke="var(--border)"/>
  <text x="280" y="32" text-anchor="middle" fill="var(--muted)">heap</text>
  <rect x="320" y="18" width="64" height="20" rx="10" fill="none" stroke="var(--border)"/>
  <text x="352" y="32" text-anchor="middle" fill="var(--muted)">code</text>
  <text x="930" y="32" text-anchor="end" fill="var(--muted)">scan idle · 0 results</text>
  <!-- scan console -->
  <rect x="64" y="48" width="620" height="72" fill="none" stroke="var(--border)"/>
  <rect x="80" y="64" width="180" height="24" fill="none" stroke="var(--accent)"/>
  <text x="90" y="80" fill="var(--fg)">value: 100</text>
  <rect x="272" y="64" width="96" height="24" fill="none" stroke="var(--border)"/>
  <text x="282" y="80" fill="var(--muted)">type: dword</text>
  <rect x="380" y="64" width="96" height="24" fill="none" stroke="var(--border)"/>
  <text x="390" y="80" fill="var(--muted)">op: exact</text>
  <rect x="488" y="64" width="80" height="24" fill="none" stroke="var(--accent)"/>
  <text x="528" y="80" text-anchor="middle" fill="var(--accent)">first</text>
  <rect x="576" y="64" width="80" height="24" fill="none" stroke="var(--border)"/>
  <text x="616" y="80" text-anchor="middle" fill="var(--muted)">next</text>
  <!-- memory-map donut -->
  <circle cx="810" cy="180" r="70" fill="none" stroke="var(--c1)" stroke-width="14" stroke-dasharray="120 320"/>
  <circle cx="810" cy="180" r="70" fill="none" stroke="var(--c2)" stroke-width="14" stroke-dasharray="60 380" stroke-dashoffset="-120"/>
  <circle cx="810" cy="180" r="70" fill="none" stroke="var(--c3)" stroke-width="14" stroke-dasharray="40 400" stroke-dashoffset="-180"/>
  <text x="810" y="176" text-anchor="middle" fill="var(--fg)">VA map</text>
  <text x="810" y="192" text-anchor="middle" fill="var(--muted)">1.2 GB</text>
  <!-- results table -->
  <rect x="64" y="120" width="620" height="300" fill="none" stroke="var(--border)"/>
  <text x="80" y="140" fill="var(--muted)">address</text>
  <text x="240" y="140" fill="var(--muted)">module+offset</text>
  <text x="420" y="140" fill="var(--muted)">value</text>
  <text x="500" y="140" fill="var(--muted)">delta</text>
  <text x="560" y="140" fill="var(--muted)">history</text>
  <line x1="64" y1="150" x2="684" y2="150" stroke="var(--border)"/>
  <text x="80" y="172" fill="var(--fg)">0x7FF6A2C01000</text>
  <text x="240" y="172" fill="var(--muted)">victim.exe+0x1F48</text>
  <text x="420" y="172" fill="var(--accent)">100</text>
  <text x="500" y="172" fill="var(--success)">+0</text>
  <polyline points="560,176 572,170 584,174 596,168 608,172 620,166" fill="none" stroke="var(--c1)"/>
  <text x="80" y="196" fill="var(--fg)">0x1A44C220</text>
  <text x="240" y="196" fill="var(--muted)">(heap)</text>
  <text x="420" y="196" fill="var(--accent)">100</text>
  <text x="500" y="196" fill="var(--warning)">+2</text>
  <polyline points="560,200 572,198 584,192 596,196 608,190 620,194" fill="none" stroke="var(--c2)"/>
  <!-- inspector -->
  <rect x="684" y="250" width="268" height="170" fill="none" stroke="var(--border)"/>
  <text x="700" y="272" fill="var(--muted)">inspector · hex</text>
  <text x="700" y="296" fill="var(--fg)">00 64 00 00 · e8 03 00 00</text>
  <text x="700" y="318" fill="var(--fg)">01 00 00 00 · 50 c3 00 00</text>
  <text x="700" y="348" fill="var(--muted)">freeze: off   [set] [jump]</text>
  <!-- scan timeline -->
  <rect x="64" y="420" width="888" height="120" fill="none" stroke="var(--border)"/>
  <text x="80" y="444" fill="var(--muted)">scan timeline</text>
  <line x1="80" y1="480" x2="930" y2="480" stroke="var(--border)"/>
  <circle cx="140" cy="480" r="5" fill="var(--accent)"/>
  <circle cx="300" cy="480" r="5" fill="none" stroke="var(--muted)"/>
  <circle cx="460" cy="480" r="5" fill="none" stroke="var(--muted)"/>
  <text x="140" y="504" text-anchor="middle" fill="var(--muted)">first</text>
  <text x="300" y="504" text-anchor="middle" fill="var(--muted)">next</text>
  <text x="460" y="504" text-anchor="middle" fill="var(--muted)">refine</text>
  <text x="930" y="444" text-anchor="end" fill="var(--muted)">Ctrl+K commands</text>
</svg>
```

## 3. Regions

| Region | Content | Unique element |
|---|---|---|
| Left rail (56px) | icon nav: process, scan, pointers, code, debug, console | active pill |
| Top bar | target chip (name/pid/attach state), region-class filter chips, live status (matches counter, throughput MB/s) | region chips drive scan ranges |
| Scan console | value / type / compare-op inputs, first-scan & next-scan actions, pattern field (AoB/group syntax) | one-line pattern language (SKILL.md §2.3) |
| Memory-map donut | full VA space as a ring: segment arc length = bytes, color = region class (`--c1..--c6`); hover shows segment; click filters scans to it | **not present in CE/GG** |
| Results table | addr, module+offset, value, **delta**, **sparkline** of last N values, freeze toggle, stability color (survived rescans → `--success`) | virtualized to 1M rows; **delta + sparkline columns are unique** |
| Inspector | hex dump of selection, value history chart, pointer candidates, quick actions (set, freeze, jump, dissect) | inline pointer candidates |
| Scan timeline | one node per scan state; scrub back to any earlier state (results + criteria); undo/redo scans | **scan state timeline is unique** (CE only has "undo scan") |
| Command palette | Ctrl+K; every action + address jump + value paste | keyboard-first |

## 4. Tech stack (decision D4)

Custom immediate-mode UI kit on `gg` + `sokol` (V's native graphics stack,
used by `vlang/ved`). Rejected `vlang/ui`: stock look conflicts with the
unique-layout requirement, less maintenance control.

`gui/uikit/` widgets (one widget per file, split rule applies):
`panel.v table_virtual.v sparkline.v donut.v palette.v chip.v input.v
hex_view.v history_chart.v theme.v`. Rendering model: retained scene built
from engine snapshots each frame; virtualized table renders only visible rows.

## 5. Interaction model

| Input | Action |
|---|---|
| Ctrl+K | command palette |
| Ctrl+F | focus scan value field |
| Enter | run scan (first or next depending on state) |
| Space | toggle freeze on selection |
| Del | remove results/entries |
| Ctrl+Z / Ctrl+Y | timeline step back / forward |
| Double-click value | inline edit |
| Double-click address | jump inspector |

## 6. Performance budget

- 60 fps with 1M result rows (virtualization: only visible rows allocate).
- No engine calls on the render thread; engine pushes immutable snapshots
  over channels (ARCHITECTURE.md §4).
- Sparkline history ring buffer per entry (fixed 64 samples, no alloc).

## 7. Android note

v1: GUI manages remote sessions (device list via agent handshake) — same radar
layout, remote sessions appear as targets with a device chip. On-device overlay
UI (floating bubble over games, GameGuardian-style) is P8+ evaluation only.
