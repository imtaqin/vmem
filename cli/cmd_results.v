module main

import vmem

// cmd_results prints the saved session hits: vmem results --state F [--limit N].
fn cmd_results(args []string) int {
	state := flag_val(args, '--state')
	if state == '' {
		eprintln('usage: vmem results --state <file> [--limit N]')
		return 1
	}
	s := vmem.load_session(state) or {
		eprintln('error: ${err.msg()}')
		return 1
	}
	limit := flag_val(args, '--limit').int()
	entries := vmem.get_results(&s, 0, limit)
	println('hits: ${vmem.result_count(&s)}')
	for e in entries {
		println('0x${e.address:x}\t${e.value}\t${e.kind}\tstable=${e.stable}')
	}
	return 0
}
