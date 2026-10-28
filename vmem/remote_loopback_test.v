module vmem

import net
import time
import vmem.sys.remote

// P3 acceptance: in-process agent instance over loopback TCP
// (AGENTS.md §2). Agent-side scan offload must produce the same results as
// host-side scanning over bulk reads.

fn serve_loop(port int) {
	mut l := remote.listen('127.0.0.1', port) or { return }
	for {
		mut conn := l.accept() or { continue }
		serve_remote_conn(mut conn) or {}
		conn.close() or {}
	}
}

fn test_remote_loopback() {
	spawn serve_loop(47123)
	time.sleep(150 * time.millisecond)

	mut r := new_remote_backend('127.0.0.1', 47123) or { panic(err) }
	mut marker := u32(0x0C0FFEE0)
	maddr := u64(unsafe { usize(&marker) })

	// error path first: read before attach maps to a VmError
	mut buf := []u8{len: 4}
	if n := r.read_bytes(0x1000, mut buf) {
		assert false, 'expected not_attached error, got ${n}'
	} else {
		assert err is VmError
	}

	// attach to self and read through the agent
	r.attach(current_pid()) or { panic(err) }
	assert r.pid() == current_pid()
	n := r.read_bytes(maddr, mut buf) or { panic(err) }
	assert n == 4
	assert decode_u32_le(buf) == u32(0x0C0FFEE0)

	// write through the agent and read back
	w := r.write_bytes(maddr, [u8(0x11), 0x22, 0x33, 0x44]) or { panic(err) }
	assert w == 4
	assert marker == u32(0x44332211)
	r.write_bytes(maddr, [u8(0xE0), 0xFE, 0x0F, 0x0C]) or { panic(err) } // restore LE
	assert marker == u32(0x0C0FFEE0)

	// regions and modules flow through the wire
	regions := r.enumerate_regions() or { panic(err) }
	assert regions.len > 0
	mods := r.enumerate_modules() or { panic(err) }
	assert mods.len > 0

	// capabilities advertise agent-side scan offload
	assert r.capabilities().scan_offload

	// AC: offload scan == host-side scan over bulk reads (tight window keeps
	// the comparison deterministic: self-scan result buffers would otherwise
	// add matches on later passes)
	plan := ScanPlan{
		kind:   .dword
		op:     .eq
		value:  f64(0x0C0FFEE0)
		filter: ScanFilter{
			start: maddr
			end:   maddr + 4
		}
	}
	mut s1 := new_scan_session()
	offloaded := r.scan_execute(plan, mut s1) or { panic(err) }
	assert offloaded == 1
	assert maddr in s1.addresses

	mut s2 := new_scan_session()
	hostside := scan_first(mut r, mut s2, plan) or { panic(err) }
	assert hostside == offloaded
	assert s2.addresses == s1.addresses

	r.detach() or {}
	marker = 0
	assert marker == 0
}
