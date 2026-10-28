module vmem

import os
import time

// Integration test against tests/victim (AGENTS.md §5): attach, region and
// module enumeration, typed r/w, suspend/resume semantics, kill.

const vexe = os.getenv('VEXE')
const victim_src = os.join_path(os.dir(@FILE), '..', 'tests', 'victim', 'victim.v')

struct VictimInfo {
mut:
	pid          int
	u32_addr     u64
	u64_addr     u64
	f32_addr     u64
	counter_addr u64
	pattern_addr u64
	text_addr    u64
	target_addr  u64
	l1_addr      u64
	l2_addr      u64
	tick_addr    u64
	pair_a_addr  u64
	pair_b_addr  u64
}

fn parse_victim_info(path string) VictimInfo {
	content := os.read_file(path) or { panic(err) }
	mut v := VictimInfo{}
	for line in content.split_into_lines() {
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		val := parts[1].u64()
		match parts[0] {
			'pid' { v.pid = int(val) }
			'u32' { v.u32_addr = val }
			'u64' { v.u64_addr = val }
			'f32' { v.f32_addr = val }
			'counter' { v.counter_addr = val }
			'pattern' { v.pattern_addr = val }
			'text' { v.text_addr = val }
			'target' { v.target_addr = val }
			'l1' { v.l1_addr = val }
			'l2' { v.l2_addr = val }
			'tick' { v.tick_addr = val }
			'pair_a' { v.pair_a_addr = val }
			'pair_b' { v.pair_b_addr = val }
			else {}
		}
	}
	return v
}

fn test_victim_full_stack() {
	// build the victim once per test run (-gc none: the victim does not need
	// a garbage collector and this keeps the build independent of libgc)
	bin := os.join_path(os.temp_dir(), 'vmem_victim.exe')
	build :=
		os.system('${os.quoted_path(vexe)} -gc none -o ${os.quoted_path(bin)} ${os.quoted_path(victim_src)}')
	assert build == 0
	info_path := os.join_path(os.temp_dir(), 'vmem_victim_info.txt')
	stop_path := info_path + '.stop'
	os.rm(info_path) or {}
	os.rm(stop_path) or {}

	mut proc := os.new_process(bin)
	proc.set_args([info_path])
	proc.run()
	defer {
		os.write_file(stop_path, 'stop') or {}
		proc.signal_kill()
		proc.wait()
		proc.close()
	}

	// wait for the victim to report
	mut info := VictimInfo{}
	for _ in 0 .. 100 {
		if os.exists(info_path) {
			info = parse_victim_info(info_path)
			if info.pid > 0 && info.u32_addr > 0 {
				break
			}
		}
		time.sleep(50 * time.millisecond)
	}
	assert info.pid > 0

	mut b := new_local_backend(info.pid) or { panic(err) }
	defer {
		b.detach() or {}
	}

	// planted scalars read back exactly (LE)
	assert read_u32(info.pid, info.u32_addr)! == u32(0x12345678)
	assert read_u64(info.pid, info.u64_addr)! == u64(0x1122334455667788)
	assert read_f32(info.pid, info.f32_addr)! == f32(1.5)

	// regions cover the planted addresses
	regions := b.enumerate_regions() or { panic(err) }
	assert regions.len > 0
	mut covered := false
	for r in regions {
		if info.u32_addr >= r.base && info.u32_addr < r.base + r.size {
			covered = true
		}
	}
	assert covered

	// modules include the victim binary
	mods := b.enumerate_modules() or { panic(err) }
	assert mods.len > 0
	assert mods[0].base > 0

	// typed write roundtrip
	write_u32(info.pid, info.counter_addr, u32(777))!
	assert read_u32(info.pid, info.counter_addr)! == u32(777)

	// text bytes at the planted address
	mut tbuf := []u8{len: 18}
	n := read_bytes(info.pid, info.text_addr, mut tbuf)!
	assert n == 18
	assert tbuf.bytestr() == 'vmem-victim-string'

	// aob bytes
	mut pbuf := []u8{len: 4}
	read_bytes(info.pid, info.pattern_addr, mut pbuf)!
	assert pbuf == [u8(0x48), 0x8B, 0x2A, 0xC3]

	// suspend freezes the mutation loop; resume restarts it
	b.suspend()!
	c1 := read_u32(info.pid, info.counter_addr)!
	time.sleep(350 * time.millisecond)
	c2 := read_u32(info.pid, info.counter_addr)!
	assert c1 == c2
	b.resume()!
	time.sleep(350 * time.millisecond)
	c3 := read_u32(info.pid, info.counter_addr)!
	assert c3 != c1

	// kill stops the process
	b.kill()!
	time.sleep(100 * time.millisecond)
	assert !proc.is_alive()
}

fn test_victim_scan_flow() {
	bin := os.join_path(os.temp_dir(), 'vmem_victim.exe')
	build :=
		os.system('${os.quoted_path(vexe)} -gc none -o ${os.quoted_path(bin)} ${os.quoted_path(victim_src)}')
	assert build == 0
	info_path := os.join_path(os.temp_dir(), 'vmem_victim_scan_info.txt')
	stop_path := info_path + '.stop'
	os.rm(info_path) or {}
	os.rm(stop_path) or {}

	mut proc := os.new_process(bin)
	proc.set_args([info_path])
	proc.run()
	defer {
		os.write_file(stop_path, 'stop') or {}
		proc.signal_kill()
		proc.wait()
		proc.close()
	}

	mut info := VictimInfo{}
	for _ in 0 .. 100 {
		if os.exists(info_path) {
			info = parse_victim_info(info_path)
			if info.pid > 0 && info.u32_addr > 0 {
				break
			}
		}
		time.sleep(50 * time.millisecond)
	}
	assert info.pid > 0

	mut b := new_local_backend(info.pid) or { panic(err) }
	defer {
		b.detach() or {}
	}
	mut s := new_scan_session()

	// exact scan finds the planted u32 at its exact address
	exact := ScanPlan{
		kind:  .dword
		op:    .eq
		value: f64(0x12345678)
	}
	n := scan_first(mut b, mut s, exact) or { panic(err) }
	assert n >= 1
	assert info.u32_addr in s.addresses

	// ranged scan (filter.start) excludes addresses below the range
	mut s2 := new_scan_session()
	ranged := ScanPlan{
		kind:   .dword
		op:     .eq
		value:  f64(0x12345678)
		filter: ScanFilter{
			start: info.u32_addr + 1
		}
	}
	scan_first(mut b, mut s2, ranged) or { panic(err) }
	assert info.u32_addr !in s2.addresses

	// counter: frozen baseline; our own writes drive the deltas so every
	// step is deterministic (the victim's 100ms tick would race live scans)
	b.suspend()!
	cur := read_u32(info.pid, info.counter_addr) or { panic(err) }
	mut s3 := new_scan_session()
	counter_plan := ScanPlan{
		kind:  .dword
		op:    .eq
		value: f64(cur)
	}
	scan_first(mut b, mut s3, counter_plan) or { panic(err) }
	assert info.counter_addr in s3.addresses
	// 9999 > cur -> increased keeps it
	write_u32(info.pid, info.counter_addr, u32(9999))!
	inc := ScanPlan{
		kind: .dword
		op:   .increased
	}
	scan_next(mut b, mut s3, inc) or { panic(err) }
	assert info.counter_addr in s3.addresses
	// 5000 < 9999 -> decreased keeps it
	write_u32(info.pid, info.counter_addr, u32(5000))!
	dec := ScanPlan{
		kind: .dword
		op:   .decreased
	}
	scan_next(mut b, mut s3, dec) or { panic(err) }
	assert info.counter_addr in s3.addresses
	// a new write between scans -> changed keeps it
	write_u32(info.pid, info.counter_addr, u32(7777))!
	chg := ScanPlan{
		kind: .dword
		op:   .changed
	}
	scan_next(mut b, mut s3, chg) or { panic(err) }
	assert info.counter_addr in s3.addresses
	// still frozen -> changed drops it now
	scan_next(mut b, mut s3, chg) or { panic(err) }
	assert info.counter_addr !in s3.addresses
	b.resume()!

	// parallel path on a real process: same planted value is found
	mut s4 := new_scan_session()
	pn := scan_first_parallel(info.pid, mut s4, exact) or { panic(err) }
	assert pn >= 1
	assert info.u32_addr in s4.addresses

	// aob pattern scan finds the planted byte sequence
	mut s5 := new_scan_session()
	pat := parse_aob('48 8B ?? C3') or { panic(err) }
	pat_plan := ScanPlan{
		kind:    .aob
		op:      .eq
		pattern: pat
	}
	an := scan_first(mut b, mut s5, pat_plan) or { panic(err) }
	assert an >= 1
	assert info.pattern_addr in s5.addresses

	// text scan finds the planted string (both encodings the victim uses)
	mut s6 := new_scan_session()
	tpat := pattern_from_text('vmem-victim-string', .utf8) or { panic(err) }
	tplan := ScanPlan{
		kind:    .text
		op:      .eq
		pattern: tpat
	}
	tn := scan_first(mut b, mut s6, tplan) or { panic(err) }
	assert tn >= 1
	assert info.text_addr in s6.addresses
}

fn test_victim_freeze_pointer() {
	bin := os.join_path(os.temp_dir(), 'vmem_victim.exe')
	build :=
		os.system('${os.quoted_path(vexe)} -gc none -o ${os.quoted_path(bin)} ${os.quoted_path(victim_src)}')
	assert build == 0
	info_path := os.join_path(os.temp_dir(), 'vmem_victim_fp_info.txt')
	stop_path := info_path + '.stop'
	os.rm(info_path) or {}
	os.rm(stop_path) or {}

	mut proc := os.new_process(bin)
	proc.set_args([info_path])
	proc.run()
	defer {
		os.write_file(stop_path, 'stop') or {}
		proc.signal_kill()
		proc.wait()
		proc.close()
	}

	mut info := VictimInfo{}
	for _ in 0 .. 100 {
		if os.exists(info_path) {
			info = parse_victim_info(info_path)
			if info.pid > 0 && info.target_addr > 0 {
				break
			}
		}
		time.sleep(50 * time.millisecond)
	}
	assert info.pid > 0

	mut b := new_local_backend(info.pid) or { panic(err) }
	defer {
		b.detach() or {}
	}

	// freeze semantics are checked against a frozen target (a live target's
	// 100ms tick races the read by design); the live pass proves rewrites
	mut f := FreezeList{}
	freeze_add(mut f, info.counter_addr, .dword, 5555, 0, 0, .normal)
	b.suspend()!
	w := freeze_tick(mut b, mut f) or { panic(err) }
	assert w >= 1
	assert read_u32(info.pid, info.counter_addr)! == u32(5555)
	b.resume()!
	// live ticker smoke: rewrites keep happening while the victim mutates
	total := freeze_run(mut b, mut f, 250) or { panic(err) }
	assert total >= 1
	b.suspend()!
	freeze_tick(mut b, mut f) or { panic(err) }
	assert read_u32(info.pid, info.counter_addr)! == u32(5555)
	b.resume()!

	// pointer scan finds the planted chain: l1 -> target, l2 -> l1 -> target
	paths := pointer_scan(mut b, info.target_addr, 0, 2, 16, ScanFilter{}) or { panic(err) }
	assert paths.len >= 2
	mut bases := []u64{}
	for p in paths {
		bases << p.base
		v := resolve_pointer(mut b, p) or { panic(err) }
		assert v == info.target_addr
	}
	assert info.l1_addr in bases
	assert info.l2_addr in bases

	// break the chain -> rescan drops every path
	write_u64(info.pid, info.l1_addr, u64(0))!
	kept := rescan_pointers(mut b, paths, info.target_addr) or { panic(err) }
	assert kept.len == 0
}

fn test_victim_inject_dll() {
	bin := os.join_path(os.temp_dir(), 'vmem_victim.exe')
	build :=
		os.system('${os.quoted_path(vexe)} -gc none -o ${os.quoted_path(bin)} ${os.quoted_path(victim_src)}')
	assert build == 0
	info_path := os.join_path(os.temp_dir(), 'vmem_victim_dll_info.txt')
	stop_path := info_path + '.stop'
	os.rm(info_path) or {}
	os.rm(stop_path) or {}

	mut proc := os.new_process(bin)
	proc.set_args([info_path])
	proc.run()
	defer {
		os.write_file(stop_path, 'stop') or {}
		proc.signal_kill()
		proc.wait()
		proc.close()
	}

	mut info := VictimInfo{}
	for _ in 0 .. 100 {
		if os.exists(info_path) {
			info = parse_victim_info(info_path)
			if info.pid > 0 {
				break
			}
		}
		time.sleep(50 * time.millisecond)
	}
	assert info.pid > 0

	mut b := new_local_backend(info.pid) or { panic(err) }
	defer {
		b.detach() or {}
	}
	// LoadLibraryW(user32.dll) in the victim returns a module handle
	handle := inject_dll(mut b, 'C:\\Windows\\System32\\user32.dll') or { panic(err) }
	assert handle != 0
}

fn spawn_victim_for(info_path string) (&os.Process, VictimInfo) {
	// per-pid exe name avoids cross-run lock collisions on Windows
	bin := os.join_path(os.temp_dir(), 'vmem_victim_${os.getpid()}.exe')
	build :=
		os.system('${os.quoted_path(vexe)} -gc none -o ${os.quoted_path(bin)} ${os.quoted_path(victim_src)}')
	assert build == 0
	stop_path := info_path + '.stop'
	os.rm(info_path) or {}
	os.rm(stop_path) or {}
	mut proc := os.new_process(bin)
	proc.set_args([info_path])
	proc.run()
	mut info := VictimInfo{}
	for _ in 0 .. 100 {
		if os.exists(info_path) {
			info = parse_victim_info(info_path)
			if info.pid > 0 && info.counter_addr > 0 {
				break
			}
		}
		time.sleep(50 * time.millisecond)
	}
	assert info.pid > 0
	return proc, info
}

fn stop_victim_for(mut proc os.Process, info_path string) {
	os.write_file(info_path + '.stop', 'stop') or {}
	proc.signal_kill()
	proc.wait()
	proc.close()
}

fn test_victim_watchpoint() {
	info_path := os.join_path(os.temp_dir(), 'vmem_victim_wp_info.txt')
	mut proc, info := spawn_victim_for(info_path)
	defer {
		stop_victim_for(mut proc, info_path)
	}

	mut b := new_local_backend(info.pid) or { panic(err) }
	defer {
		b.detach() or {}
	}
	// AC: breakpoint on victim write hits with correct register state
	mut dbg := debug_attach(mut b) or { panic(err) }
	slot := dbg.set_breakpoint(info.counter_addr, .write, 4) or { panic(err) }
	assert slot == 0
	hit := dbg.wait_hit(5000) or { panic(err) }
	assert hit.tid != 0
	assert hit.dr6 & 0x1 != 0 // slot 0 fired
	assert hit.regs.dr0 == info.counter_addr // correct register state
	assert hit.regs.rip != 0
	dbg.clear_breakpoint(0) or { panic(err) }
	dbg.detach() or { panic(err) }
	// target still alive after detach (kill-on-exit off)
	assert proc.is_alive()
}

fn test_victim_speedhack() {
	info_path := os.join_path(os.temp_dir(), 'vmem_victim_sh_info.txt')
	mut proc, info := spawn_victim_for(info_path)
	defer {
		stop_victim_for(mut proc, info_path)
	}

	mut b := new_local_backend(info.pid) or { panic(err) }
	defer {
		b.detach() or {}
	}
	// AC: speedhack scales victim timer reads 0.1x-10x
	mut sh := speedhack_install(mut b, 0.1) or { panic(err) }
	// let the victim's loop publish hooked (virtual) ticks before sampling
	time.sleep(150 * time.millisecond)
	speedhack_tick(mut b, mut sh, 150) or { panic(err) }
	t0 := read_u64(info.pid, info.tick_addr) or { panic(err) }
	for _ in 0 .. 4 {
		time.sleep(100 * time.millisecond)
		speedhack_tick(mut b, mut sh, 100) or { panic(err) }
	}
	t1 := read_u64(info.pid, info.tick_addr) or { panic(err) }
	// ~400ms real elapsed -> ~40ms of scaled ticks
	assert t1 - t0 < 200
	speedhack_remove(mut b, sh) or { panic(err) }
	// restored: real-time ticks again (sample after the loop refreshes)
	time.sleep(150 * time.millisecond)
	t2 := read_u64(info.pid, info.tick_addr) or { panic(err) }
	time.sleep(300 * time.millisecond)
	t3 := read_u64(info.pid, info.tick_addr) or { panic(err) }
	assert t3 - t2 >= 200
}

fn test_victim_dissect() {
	info_path := os.join_path(os.temp_dir(), 'vmem_victim_dis_info.txt')
	mut proc, info := spawn_victim_for(info_path)
	defer {
		stop_victim_for(mut proc, info_path)
	}

	mut b := new_local_backend(info.pid) or { panic(err) }
	defer {
		b.detach() or {}
	}
	// AC: dissect finds planted struct offsets in victim (byte offsets;
	// 999 and 888 each flip two LE bytes of their u32 cell)
	offs := find_offsets(mut b, info.pair_a_addr, info.pair_b_addr, 64) or { panic(err) }
	assert offs == [12, 13, 28, 29]

	// heuristic field inspection sees the planted dword values
	guesses := dissect_struct(mut b, info.pair_a_addr, 64) or { panic(err) }
	assert guesses.len >= 16
	assert guesses[0].value == 100
	assert guesses[0].notes == ''
}
