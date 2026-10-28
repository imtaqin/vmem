module vmem

// Freeze semantics tests over the fake backend (deterministic; the victim
// integration covers the live-ticker smoke).

fn freeze_mem() []u8 {
	mut mem := []u8{len: 256}
	encode_u32_le(u32(100), mut mem[0x20..0x24])
	encode_u32_le(u32(10), mut mem[0x40..0x44])
	encode_u32_le(u32(30), mut mem[0x60..0x64])
	encode_u32_le(u32(5), mut mem[0x80..0x84])
	return mem
}

fn freeze_read(mut b FakeBackend, addr u64) f64 {
	mut buf := []u8{len: 4}
	b.read_bytes(addr, mut buf) or { panic(err) }
	return decode_kind_num(.dword, buf)
}

fn test_freeze_normal() {
	mut b := new_fake_backend(1, 0x1000, freeze_mem())
	mut f := FreezeList{}
	freeze_add(mut f, 0x1020, .dword, 55, 0, 0, .normal)
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 1
	assert freeze_read(mut b, 0x1020) == 55
	// a "game" write is reverted on the next tick
	mut buf := []u8{len: 4}
	encode_u32_le(u32(70), mut buf)
	b.write_bytes(0x1020, buf) or { panic(err) }
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 1
	assert freeze_read(mut b, 0x1020) == 55
	assert f.entries[0].writes == 2
	// remove stops the writes
	freeze_remove(mut f, 0)
	assert f.entries.len == 0
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 0
}

fn test_freeze_may_increase() {
	mut b := new_fake_backend(1, 0x1000, freeze_mem())
	mut f := FreezeList{}
	freeze_add(mut f, 0x1020, .dword, 55, 0, 0, .may_increase)
	// 100 > 55 -> not written (value may stay above)
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 0
	assert freeze_read(mut b, 0x1020) == 100
	// drop below -> written up to 55
	mut buf := []u8{len: 4}
	encode_u32_le(u32(40), mut buf)
	b.write_bytes(0x1020, buf) or { panic(err) }
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 1
	assert freeze_read(mut b, 0x1020) == 55
}

fn test_freeze_may_decrease() {
	mut b := new_fake_backend(1, 0x1000, freeze_mem())
	mut f := FreezeList{}
	freeze_add(mut f, 0x1040, .dword, 15, 0, 0, .may_decrease)
	// 10 < 15 -> not written (value may stay below)
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 0
	assert freeze_read(mut b, 0x1040) == 10
	// rise above -> written down to 15
	mut buf := []u8{len: 4}
	encode_u32_le(u32(25), mut buf)
	b.write_bytes(0x1040, buf) or { panic(err) }
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 1
	assert freeze_read(mut b, 0x1040) == 15
}

fn test_freeze_in_range() {
	mut b := new_fake_backend(1, 0x1000, freeze_mem())
	mut f := FreezeList{}
	// 0x60 holds 30 -> clamped up to 40
	freeze_add(mut f, 0x1060, .dword, 0, 40, 60, .in_range)
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 1
	assert freeze_read(mut b, 0x1060) == 40
	// in range -> untouched
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 0
	// 0x80 holds 5 -> clamped up to 40
	freeze_add(mut f, 0x1080, .dword, 0, 40, 60, .in_range)
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 1
	assert freeze_read(mut b, 0x1080) == 40
	// above range -> clamped down
	mut buf := []u8{len: 4}
	encode_u32_le(u32(90), mut buf)
	b.write_bytes(0x1060, buf) or { panic(err) }
	assert (freeze_tick(mut b, mut f) or { panic(err) }) == 1
	assert freeze_read(mut b, 0x1060) == 60
}
