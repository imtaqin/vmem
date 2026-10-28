#!/usr/bin/env node
// Vmem docs/conventions MCP server — zero dependencies.
// Transport: MCP stdio (newline-delimited JSON-RPC 2.0).
// All tools are read-only; the markdown docs are the single source of truth.
import fs from 'node:fs'
import path from 'node:path'
import readline from 'node:readline'
import { fileURLToPath } from 'node:url'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const REG = JSON.parse(fs.readFileSync(path.join(ROOT, 'mcp', 'registry.json'), 'utf8'))

// ---------- doc access ----------

const docCache = new Map()
function docPath(key) {
  const d = REG.docs[key]
  if (!d) throw new Error(`unknown doc '${key}'; known: ${Object.keys(REG.docs).join(', ')}`)
  return d.path
}
function docText(key) {
  if (!docCache.has(key)) {
    const p = path.join(ROOT, docPath(key))
    docCache.set(key, fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : '')
  }
  return docCache.get(key)
}
function headingLevel(line) {
  const m = /^(\s*)(#{1,6})\s/.exec(line)
  return m ? m[2].length : 0
}
// extract section whose heading starts with `prefix` (e.g. "## 2. Layering")
function extractSection(text, prefix) {
  const lines = text.split(/\r?\n/)
  const at = lines.findIndex((l) => {
    const lv = headingLevel(l)
    return lv > 0 && l.trim().replace(/^#+\s*/, '').startsWith(prefix.replace(/^#+\s*/, ''))
  })
  if (at < 0) return null
  const level = headingLevel(lines[at])
  let end = lines.length
  for (let i = at + 1; i < lines.length; i++) {
    const lv = headingLevel(lines[i])
    if (lv > 0 && lv <= level) { end = i; break }
  }
  return lines.slice(at, end).join('\n').trim()
}
function listSections(key) {
  return docText(key)
    .split(/\r?\n/)
    .filter((l) => headingLevel(l) > 0)
    .map((l) => l.trim())
}
function parseTables(text) {
  const tables = []
  let cur = null
  for (const line of text.split(/\r?\n/)) {
    const t = line.trim()
    if (/^\|.*\|$/.test(t)) {
      const cells = t.slice(1, -1).split('|').map((c) => c.trim())
      if (cells.every((c) => /^:?-{2,}:?$/.test(c))) continue // separator row
      if (!cur) { cur = []; tables.push(cur) }
      cur.push(cells)
    } else cur = null
  }
  return tables
}

// ---------- tools ----------

function hit(doc, path_, line, text) {
  return { doc, path: path_, line, text: text.length > 160 ? text.slice(0, 157) + '...' : text }
}
function searchDocs({ query, doc, caseSensitive }) {
  if (!query) throw new Error('query required')
  const literal = !(query.startsWith('/') && query.lastIndexOf('/') > 0)
  const re = literal
    ? new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), caseSensitive ? 'g' : 'gi')
    : new RegExp(query.slice(1, query.lastIndexOf('/')), caseSensitive ? 'g' : 'gi')
  const keys = doc ? [doc] : Object.keys(REG.docs)
  const hits = []
  for (const key of keys) {
    const lines = docText(key).split(/\r?\n/)
    for (let i = 0; i < lines.length; i++) {
      re.lastIndex = 0
      if (re.test(lines[i])) {
        hits.push(hit(key, REG.docs[key].path, i + 1, lines[i].trim()))
        if (hits.length >= 50) return { query, hits, truncated: true }
      }
    }
  }
  return { query, hits, truncated: false }
}
function readDoc({ doc, section, fromLine, toLine }) {
  const text = docText(doc)
  if (section) {
    const s = extractSection(text, section)
    if (s == null) throw new Error(`no section starting with '${section}' in ${docPath(doc)}`)
    return `// ${docPath(doc)} — section "${section}"\n${s}`
  }
  const lines = text.split(/\r?\n/)
  const a = Math.max(1, fromLine || 1)
  const b = Math.min(lines.length, toLine || lines.length)
  return `// ${docPath(doc)} lines ${a}-${b} of ${lines.length}\n` + lines.slice(a - 1, b).join('\n')
}
function listDocs() {
  return Object.entries(REG.docs).map(([key, d]) => ({
    key,
    path: d.path,
    what: d.what,
    lines: docText(key) ? docText(key).split(/\r?\n/).length : 0,
    headings: listSections(key).slice(0, 12),
  }))
}
function fromHeadingMap(mapName, mapDocKey, id) {
  const map = REG[mapName]
  const prefix = map[id]
  if (!prefix) throw new Error(`unknown ${mapName.slice(0, -1)} '${id}'; known: ${Object.keys(map).join(', ')}`)
  const docKey = REG[`${mapName}Doc`] || mapDocKey
  const s = extractSection(docText(docKey), prefix)
  if (s == null) throw new Error(`section '${prefix}' not found in ${docPath(docKey)}`)
  return s
}
function getPhase({ id }) {
  const cfg = REG.phases
  const s = extractSection(docText(cfg.doc), cfg.headingPrefix + (id || ''))
  if (s == null) throw new Error(`no phase '${id}' in ${docPath(cfg.doc)}; use P0..P8`)
  return s
}
function getPlatform({ query }) {
  const out = []
  for (const sec of REG.platform.sections) {
    const s = extractSection(docText(REG.platform.doc), sec)
    if (!s) continue
    for (const table of parseTables(s)) {
      const rows = query
        ? table.filter((r) => r.some((c) => c.toLowerCase().includes(query.toLowerCase())))
        : table
      if (rows.length) out.push({ section: sec, rows })
    }
  }
  return out
}
function getParity({ query, phase }) {
  const all = parseTables(docText(REG.parity.doc)).flat()
  let rows = all.filter((r) => r.length === 5 && r[4] && /^(P\d|later|—)/.test(r[4]))
  if (query) rows = rows.filter((r) => r[0].toLowerCase().includes(query.toLowerCase()))
  if (phase) rows = rows.filter((r) => r[4].includes(phase))
  return rows.map(([feature, ce, gg, vmem, ph]) => ({ feature, cheatEngine: ce, gameGuardian: gg, vmem, phase: ph }))
}
function repoContext() {
  return {
    project: REG.project,
    title: REG.title,
    status: REG.status,
    howTo: 'docs are the source of truth: use search_docs / read_doc / get_rules / get_recipe / get_vref / get_phase / get_platform / get_parity instead of reading files wholesale',
    hardRules: [
      'OS/transport API calls only in vmem/sys/ and agent/ (AGENTS.md §2)',
      'one function = one file; decl_<os>.c.v groups C prototypes (AGENTS.md §3)',
      'public fallible fns return !T; never panic on OS errors (AGENTS.md §4)',
      'scan hot paths: zero allocation after setup (AGENTS.md §4)',
      'every memory-affecting change → CHANGELOG.md ### Memory (same PR)',
      'Android = frida-style host↔agent over ADB/TCP, not a Termux CLI (D1)',
    ],
    nextPhase: extractSection(docText(REG.phases.doc), '### P0')?.split('\n').slice(0, 3).join('\n'),
    docs: Object.fromEntries(Object.entries(REG.docs).map(([k, d]) => [k, d.what])),
  }
}
function checkStructure() {
  const violations = []
  const walk = (dir) => {
    const out = []
    if (!fs.existsSync(dir)) return out
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name)
      const rel = path.relative(ROOT, p).split(path.sep).join('/')
      if (e.isDirectory()) out.push(...walk(p))
      else if (e.name.endsWith('.v')) out.push(rel)
    }
    return out
  }
  const files = walk(ROOT)
  for (const chk of REG.structureChecks) {
    if (chk.kind === 'fileContains') {
      const p = path.join(ROOT, chk.file)
      const ok = fs.existsSync(p) && new RegExp(chk.regex).test(fs.readFileSync(p, 'utf8'))
      if (!ok) violations.push({ ...chk, at: chk.file })
      continue
    }
    for (const rel of files) {
      if (chk.include?.length && !chk.include.some((i) => rel.startsWith(i))) continue
      if (chk.exclude?.some((i) => rel.startsWith(i) || rel.endsWith(i))) continue
      const text = fs.readFileSync(path.join(ROOT, rel), 'utf8')
      const lines = text.split(/\r?\n/)
      if (chk.kind === 'lineCount') {
        if (lines.length > chk.max) violations.push({ ...chk, at: rel, detail: `${lines.length} lines` })
      } else if (chk.kind === 'pubFnCount') {
        const n = lines.filter((l) => /^pub\s+fn\s/.test(l)).length
        if (n > chk.max) violations.push({ ...chk, at: rel, detail: `${n} pub fn` })
      } else if (chk.kind === 'regex') {
        const re = new RegExp(chk.regex, 'g')
        const first = lines.findIndex((l) => { re.lastIndex = 0; return re.test(l) })
        if (first >= 0) violations.push({ ...chk, at: `${rel}:${first + 1}` })
      }
    }
  }
  return { filesScanned: files.length, violations, clean: violations.filter((v) => v.severity === 'error').length === 0 }
}
function planFiles({ name, os }) {
  if (!/^[a-z][a-z0-9_]*$/.test(name || '')) throw new Error('name must be snake_case identifier')
  const oss = os?.length ? os : ['windows', 'linux']
  return {
    function: name,
    create: [
      `vmem/${name}.v — the function body (one function per file)`,
      `vmem/${name}_test.v — unit/integration test beside it`,
      ...oss.map((o) => `vmem/sys/${name}_${o}.c.v — OS-specific body (if not expressible in the base file)`),
      `vmem/sys/${name}_default.c.v — fallback returning EUnsupported`,
    ],
    update: [
      `vmem/sys/decl_<os>.c.v — add C prototypes/#include/#flag if new OS symbols are used`,
      `vmem/sys/fake/ — fake-backend entry for engine tests`,
      'CHANGELOG.md → ### Memory entry if the change affects memory semantics',
      'docs/FEATURE-PARITY.md → row/status if user-visible capability changes',
    ],
    rules: ['AGENTS.md §3 (file structure)', 'AGENTS.md §4 (API conventions)', 'AGENTS.md §5 (testing)'],
  }
}

const TOOLS = [
  { name: 'repo_context', description: 'One-call bootstrap: project status, hard rules, doc map, next phase. Use FIRST when starting work in the Vmem repo.', inputSchema: { type: 'object', properties: {}, additionalProperties: false } },
  { name: 'list_docs', description: 'Inventory of all documentation with line counts and headings.', inputSchema: { type: 'object', properties: {}, additionalProperties: false } },
  { name: 'read_doc', description: 'Read a doc by key (see list_docs), optionally one section by heading prefix or a line range. Prefer section reads over whole files.', inputSchema: { type: 'object', properties: { doc: { type: 'string' }, section: { type: 'string', description: 'heading prefix, e.g. "## 2. Layering"' }, fromLine: { type: 'integer' }, toLine: { type: 'integer' } }, required: ['doc'], additionalProperties: false } },
  { name: 'search_docs', description: 'Regex or literal search across all docs; returns file:line hits (max 50). Query like /regex/ for regex, otherwise literal, case-insensitive.', inputSchema: { type: 'object', properties: { query: { type: 'string' }, doc: { type: 'string', description: 'optional doc key to scope' }, caseSensitive: { type: 'boolean' } }, required: ['query'], additionalProperties: false } },
  { name: 'get_rules', description: 'Normative operating rules from AGENTS.md: layering | files | api | testing | docs-sync | safety | style.', inputSchema: { type: 'object', properties: { section: { type: 'string', enum: ['layering', 'files', 'api', 'testing', 'docs-sync', 'safety', 'style'] } }, required: ['section'], additionalProperties: false } },
  { name: 'get_recipe', description: 'Step-by-step repo recipe: typed-read | scan-op | agent-rpc | os-backend.', inputSchema: { type: 'object', properties: { id: { type: 'string', enum: ['typed-read', 'scan-op', 'agent-rpc', 'os-backend'] } }, required: ['id'], additionalProperties: false } },
  { name: 'get_vref', description: 'V language quick reference: syntax | errors | files | interop | concurrency | build.', inputSchema: { type: 'object', properties: { topic: { type: 'string', enum: ['syntax', 'errors', 'files', 'interop', 'concurrency', 'build'] } }, required: ['topic'], additionalProperties: false } },
  { name: 'get_phase', description: 'Phase block with acceptance criteria from docs/PLAN.md (P0..P8).', inputSchema: { type: 'object', properties: { id: { type: 'string' } }, required: ['id'], additionalProperties: false } },
  { name: 'get_platform', description: 'Platform capability matrices (Windows/Linux/macOS APIs, Android agent ops); optional substring query filters rows.', inputSchema: { type: 'object', properties: { query: { type: 'string' } }, additionalProperties: false } },
  { name: 'get_parity', description: 'Cheat Engine / GameGuardian feature matrix rows; filter by feature substring and/or phase (e.g. "P3").', inputSchema: { type: 'object', properties: { query: { type: 'string' }, phase: { type: 'string' } }, additionalProperties: false } },
  { name: 'check_structure', description: 'Validate the repo tree against AGENTS.md hard rules (layering, one-fn-per-file, changelog discipline).', inputSchema: { type: 'object', properties: {}, additionalProperties: false } },
  { name: 'plan_files', description: 'Exact file manifest to create/update when adding a named function, per the split rules.', inputSchema: { type: 'object', properties: { name: { type: 'string' }, os: { type: 'array', items: { type: 'string' } } }, required: ['name'], additionalProperties: false } },
]

const RESOURCES = Object.entries(REG.docs).map(([key, d]) => ({
  uri: `vmem://docs/${key}`,
  name: key,
  description: d.what,
  mimeType: 'text/markdown',
}))

const PROMPTS = [{
  name: 'feature-scaffold',
  description: 'Guide for adding a new capability to Vmem following the recipes and hard rules.',
  arguments: [{ name: 'name', description: 'function/capability name (snake_case)', required: true }],
}]

// ---------- dispatch ----------

function textResult(text) {
  return { content: [{ type: 'text', text }], isError: false }
}
function callTool(name, args = {}) {
  switch (name) {
    case 'repo_context': return repoContext()
    case 'list_docs': return listDocs()
    case 'read_doc': return readDoc(args)
    case 'search_docs': return searchDocs(args)
    case 'get_rules': return fromHeadingMap('rules', 'agents', args.section)
    case 'get_recipe': return fromHeadingMap('recipes', 'skill', args.id)
    case 'get_vref': return fromHeadingMap('vref', 'skill', args.topic)
    case 'get_phase': return getPhase(args)
    case 'get_platform': return getPlatform(args)
    case 'get_parity': return getParity(args)
    case 'check_structure': return checkStructure()
    case 'plan_files': return planFiles(args)
    default: throw new Error(`unknown tool '${name}'`)
  }
}

function reply(id, result) {
  process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, result }) + '\n')
}
function replyErr(id, code, message) {
  process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, error: { code, message } }) + '\n')
}

const rl = readline.createInterface({ input: process.stdin, terminal: false })
rl.on('line', (line) => {
  line = line.trim()
  if (!line) return
  let msg
  try { msg = JSON.parse(line) } catch { return }
  const { id, method, params } = msg
  if (id === undefined) return // notification
  try {
    switch (method) {
      case 'initialize':
        reply(id, {
          protocolVersion: params?.protocolVersion || '2025-06-18',
          capabilities: { tools: {}, resources: {}, prompts: {} },
          serverInfo: { name: 'vmem', version: '0.1.0' },
        })
        break
      case 'ping': reply(id, {}); break
      case 'tools/list': reply(id, { tools: TOOLS }); break
      case 'tools/call': {
        const r = callTool(params?.name, params?.arguments)
        reply(id, textResult(typeof r === 'string' ? r : JSON.stringify(r, null, 1)))
        break
      }
      case 'resources/list': reply(id, { resources: RESOURCES }); break
      case 'resources/read': {
        const uri = params?.uri || ''
        const key = uri.replace('vmem://docs/', '')
        if (!REG.docs[key]) { replyErr(id, -32002, `unknown resource ${uri}`); break }
        reply(id, { contents: [{ uri, mimeType: 'text/markdown', text: docText(key) }] })
        break
      }
      case 'prompts/list': reply(id, { prompts: PROMPTS }); break
      case 'prompts/get': {
        const name = params?.arguments?.name || '<function_name>'
        reply(id, {
          description: PROMPTS[0].description,
          messages: [{
            role: 'user',
            content: {
              type: 'text',
              text: `Add '${name}' to Vmem.\n1. get_rules section "files" and "api" — obey them exactly.\n2. plan_files name=${name} — create that manifest (real code, no stubs).\n3. get_recipe id matching the kind (typed-read | scan-op | agent-rpc | os-backend).\n4. Add a test beside the file; run the repo checks.\n5. If memory semantics change: CHANGELOG.md ### Memory entry in the same change.\n6. Update docs/FEATURE-PARITY.md status if a planned capability lands.`,
            },
          }],
        })
        break
      }
      default: replyErr(id, -32601, `method not found: ${method}`)
    }
  } catch (e) {
    if (id !== undefined) replyErr(id, -32603, String(e?.message || e))
  }
})
