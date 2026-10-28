#!/usr/bin/env node
// Sync the canonical SKILL.md into every agent's skill directory.
// Single source of truth: <repo>/SKILL.md (registry.json defines the targets).
// Usage:
//   node mcp/sync-skills.mjs           # sync project + user skill dirs
//   node mcp/sync-skills.mjs --project # project dirs only
//   node mcp/sync-skills.mjs --check   # verify copies match; exit 1 on drift
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const REG = JSON.parse(fs.readFileSync(path.join(ROOT, 'mcp', 'registry.json'), 'utf8'))
const SRC = path.join(ROOT, REG.docs.skill.path)
const args = process.argv.slice(2)
const check = args.includes('--check')
const projectOnly = args.includes('--project')

const expand = (p) => (p.startsWith('~') ? path.join(os.homedir(), p.slice(1)) : path.join(ROOT, p))
const targets = [
  ...(REG.docs.skill.targets || []),
  ...(projectOnly ? [] : REG.docs.skill.userTargets || []),
]

if (!fs.existsSync(SRC)) {
  console.error(`canonical skill missing: ${SRC}`)
  process.exit(1)
}
const srcBuf = fs.readFileSync(SRC)
let drift = 0
for (const t of targets) {
  const dst = expand(t)
  const same = fs.existsSync(dst) && Buffer.compare(fs.readFileSync(dst), srcBuf) === 0
  if (check) {
    console.log(`${same ? 'ok     ' : 'DRIFT  '} ${t}`)
    if (!same) drift++
  } else {
    fs.mkdirSync(path.dirname(dst), { recursive: true })
    if (!same) {
      fs.writeFileSync(dst, srcBuf)
      console.log(`synced ${t}`)
    } else {
      console.log(`ok     ${t}`)
    }
  }
}
if (check && drift) {
  console.error(`${drift} copy(ies) out of sync — run: node mcp/sync-skills.mjs`)
  process.exit(1)
}
