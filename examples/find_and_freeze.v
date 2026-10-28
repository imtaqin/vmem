module main

import os
import vmem

// find_and_freeze — the canonical vmem recipe (README "Examples").
// Attaches to a pid, scans for a value and freezes every hit.
// Use only on processes you own or are authorized to test.
//
//   v run examples/find_and_freeze -- <pid> <value> [seconds]
fn main() {
	args := os.args[1..]
	if args.len < 2 {
		eprintln('usage: v run examples/find_and_freeze -- <pid> <value> [seconds]')
		exit(1)
	}
	pid := args[0].int()
	value := args[1].f64()
	seconds := if args.len > 2 { args[2].int() } else { 10 }

	mut b := vmem.new_local_backend(pid) or {
		eprintln('attach failed: ${err.msg()}')
		exit(1)
	}
	defer {
		b.detach() or {}
	}
	mut s := vmem.new_scan_session()
	plan := vmem.ScanPlan{
		kind:  .dword
		op:    .eq
		value: value
	}
	n := vmem.scan_first(mut b, mut s, plan) or {
		eprintln('scan failed: ${err.msg()}')
		exit(1)
	}
	println('found ${n} hits; freezing at ${value} for ${seconds}s')
	mut f := vmem.FreezeList{}
	for e in vmem.get_results(&s, 0, 0) {
		vmem.freeze_add(mut f, e.address, e.kind, value, 0, 0, .normal)
		println('frozen 0x${e.address:x}')
	}
	writes := vmem.freeze_run(mut b, mut f, seconds * 1000) or {
		eprintln('freeze failed: ${err.msg()}')
		exit(1)
	}
	println('done: ${writes} rewrites')
}
