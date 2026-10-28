module main

import sync
import time
import vmem

// Background freeze ticker: keeps address-list values frozen while the game
// runs (10 Hz). Engine access is serialized with app.mu.

fn (mut app App) freeze_ticker() {
	for {
		time.sleep(100 * time.millisecond)
		if !app.freeze_loop || !app.attached {
			continue
		}
		app.mu.lock()
		vmem.freeze_tick(mut app.b, mut app.f) or {}
		app.mu.unlock()
	}
}

// snapshot_table re-reads current values for the address list.
fn (mut app App) snapshot_table() {
	app.mu.lock()
	for i in 0 .. app.table.len {
		if app.table[i].frozen {
			continue
		}
		t := app.table[i].kind
		v := read_val(mut app.b, t, app.table[i].addr) or { continue }
		app.table[i].value = v
	}
	app.mu.unlock()
}

// read_val reads one decoded value of the given kind.
fn read_val(mut b vmem.LocalBackend, kind vmem.ValueKind, addr u64) !f64 {
	mut buf := []u8{len: vmem.kind_size(kind)}
	n := b.read_bytes(addr, mut buf)!
	if n != buf.len {
		return error('short read')
	}
	return match kind {
		.byte {
			f64(buf[0])
		}
		.word {
			f64(u16(buf[0]) | (u16(buf[1]) << 8))
		}
		.dword {
			f64(u32(buf[0]) | (u32(buf[1]) << 8) | (u32(buf[2]) << 16) | (u32(buf[3]) << 24))
		}
		.qword {
			mut v := u64(0)
			for j in 0 .. 8 {
				v |= u64(buf[j]) << (8 * u64(j))
			}
			f64(i64(v))
		}
		.float {
			f64(unsafe { *(&f32(&buf[0])) })
		}
		else {
			unsafe { *(&f64(&buf[0])) }
		}
	}
}
