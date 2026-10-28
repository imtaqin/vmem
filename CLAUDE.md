# CLAUDE.md

Normative operating rules for this repo live in `AGENTS.md` — read it first
(layering, one-function-per-file, API conventions, testing, changelog discipline).

Domain reference (V language + memory tooling): `SKILL.md`, also available as
the `vmem` skill. Doc queries: the `vmem` MCP server (`mcp__vmem__*` tools:
`repo_context` first, then `search_docs` / `read_doc` / `get_rules` /
`get_recipe` / `get_vref` / `get_phase` / `get_platform` / `get_parity` /
`check_structure` / `plan_files`).
