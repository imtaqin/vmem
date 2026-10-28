module main

import os
import time

// victim is the deterministic target process for integration tests
// (AGENTS.md §5). It plants known values, prints their addresses to the
// info file passed as argv[1], then mutates `counter` until a
// `<info>.stop` file appears.
struct Planted {
mut:
	u32_val  u32 = u32(0x12345678)
	u64_val  u64 = u64(0x1122334455667788)
	f32_val  f32 = f32(1.5)
	counter  u32
	target   u32 = u32(0x71717171)
	l1       u64
	l2       u64
	tick_now u64
	pair_a   [16]u32
	pair_b   [16]u32
}

fn main() {
	out_path := if os.args.len > 1 { os.args[1] } else { 'victim_info.txt' }
	mut p := &Planted{}
	p.counter = u32(1000)
	p.l1 = u64(unsafe { usize(&p.target) })
	p.l2 = u64(unsafe { usize(&p.l1) })
	// struct pair for the dissect/offset finder: identical except at 3 and 7
	for i in 0 .. 16 {
		p.pair_a[i] = u32(100 + i)
		p.pair_b[i] = u32(100 + i)
	}
	p.pair_b[3] = 999
	p.pair_b[7] = 888
	mut pattern := [u8(0x48), 0x8B, 0x2A, 0xC3]
	mut text := 'vmem-victim-string'.bytes()
	mut lines := []string{}
	lines << 'pid=${os.getpid()}'
	lines << 'u32=${u64(unsafe { usize(&p.u32_val) })}'
	lines << 'u64=${u64(unsafe { usize(&p.u64_val) })}'
	lines << 'f32=${u64(unsafe { usize(&p.f32_val) })}'
	lines << 'counter=${u64(unsafe { usize(&p.counter) })}'
	lines << 'pattern=${u64(unsafe { usize(&pattern[0]) })}'
	lines << 'text=${u64(unsafe { usize(&text[0]) })}'
	lines << 'target=${u64(unsafe { usize(&p.target) })}'
	lines << 'l1=${u64(unsafe { usize(&p.l1) })}'
	lines << 'l2=${u64(unsafe { usize(&p.l2) })}'
	lines << 'tick=${u64(unsafe { usize(&p.tick_now) })}'
	lines << 'pair_a=${u64(unsafe { usize(&p.pair_a[0]) })}'
	lines << 'pair_b=${u64(unsafe { usize(&p.pair_b[0]) })}'
	os.write_file(out_path, lines.join('\n')) or { panic(err) }
	for {
		time.sleep(100 * time.millisecond)
		p.counter = p.counter + 1
		p.tick_now = u64(time.ticks())
		if os.exists(out_path + '.stop') {
			break
		}
	}
}
