module main

import os
import vmem
import vmem.sys.remote

// vmemd — the Vmem device agent (docs/PLATFORM-API.md §4).
// Static Linux ELF on Android, started via su/Magisk; expose with
// `adb forward tcp:27042 tcp:27042`, then connect the host library.
//
// Usage: vmemd [port]   (default 27042, listens on 127.0.0.1)
fn main() {
	port := if os.args.len > 1 { os.args[1].int() } else { 27042 }
	println('vmemd listening on 127.0.0.1:${port}')
	mut listener := remote.listen('127.0.0.1', port) or {
		eprintln('listen failed: ${err.msg()}')
		exit(1)
	}
	defer {
		listener.close() or {}
	}
	for {
		mut conn := listener.accept() or {
			eprintln('accept failed: ${err.msg()}')
			continue
		}
		vmem.serve_remote_conn(mut conn) or { eprintln('session ended: ${err.msg()}') }
		conn.close() or {}
	}
}
