module vmem

// expect_err_kind asserts err is a VmError carrying kind want.
fn expect_err_kind(err IError, want ErrKind) {
	if err is VmError {
		assert err.kind == want
	} else {
		assert false, 'expected VmError, got: ${err.msg()}'
	}
}

// backend_pid exercises MemoryBackend dispatch on a FakeBackend.
fn backend_pid(mut b MemoryBackend) int {
	return b.pid()
}

// backend_roundtrip exercises mut MemoryBackend dispatch on a FakeBackend.
fn backend_roundtrip(mut b MemoryBackend, addr u64) !int {
	w := [u8(7)]
	b.write_bytes(addr, w)!
	mut out := []u8{len: 1}
	b.read_bytes(addr, mut out)!
	return int(out[0])
}

fn test_fake_backend_pid_attach_capabilities() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 16})
	assert b.pid() == 42
	assert b.attached
	caps := b.capabilities()
	assert !caps.scan_offload
	assert !caps.regs
	assert !caps.alloc
	assert !caps.inject
	// re-attach while attached is allowed and retargets
	b.attach(99) or { panic(err) }
	assert b.pid() == 99
	assert b.attached
}

fn test_fake_backend_read_write_roundtrip_u32_le() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 32})
	// plain byte pattern roundtrip
	pat := [u8(0xDE), 0xAD, 0xBE, 0xEF]
	nw := b.write_bytes(0x1004, pat) or { panic(err) }
	assert nw == 4
	mut pat_r := []u8{len: 4}
	nr := b.read_bytes(0x1004, mut pat_r) or { panic(err) }
	assert nr == 4
	assert pat_r == pat
	// u32 LE roundtrip through the internal codec
	mut src := []u8{len: 4}
	encode_u32_le(u32(0x89ABCDEF), mut src)
	b.write_bytes(0x1010, src) or { panic(err) }
	mut dst := []u8{len: 4}
	b.read_bytes(0x1010, mut dst) or { panic(err) }
	assert decode_u32_le(dst) == u32(0x89ABCDEF)
	// last 4 bytes of the mapping are addressable (end boundary inclusive)
	end := b.base + u64(b.mem.len)
	mut tail := []u8{len: 4}
	encode_u32_le(u32(0x11223344), mut tail)
	b.write_bytes(end - 4, tail) or { panic(err) }
	mut tail_r := []u8{len: 4}
	b.read_bytes(end - 4, mut tail_r) or { panic(err) }
	assert decode_u32_le(tail_r) == u32(0x11223344)
}

fn test_fake_backend_empty_buf_returns_zero() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 8})
	mut empty := []u8{len: 0}
	nr := b.read_bytes(0x9999, mut empty) or { panic(err) }
	assert nr == 0
	nw := b.write_bytes(0x9999, empty) or { panic(err) }
	assert nw == 0
}

fn test_fake_backend_read_past_end_errors_range() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 16})
	mut buf := []u8{len: 8}
	b.read_bytes(0x1010, mut buf) or {
		expect_err_kind(err, .range)
		return
	}
	assert false, 'expected .range error'
}

fn test_fake_backend_read_below_base_errors_range() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 16})
	mut buf := []u8{len: 4}
	b.read_bytes(0x0FFF, mut buf) or {
		expect_err_kind(err, .range)
		return
	}
	assert false, 'expected .range error'
}

fn test_fake_backend_write_past_end_errors_range() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 16})
	buf := [u8(1), 2, 3, 4, 4, 3, 2, 1]
	b.write_bytes(0x1010, buf) or {
		expect_err_kind(err, .range)
		return
	}
	assert false, 'expected .range error'
}

fn test_fake_backend_write_below_base_errors_range() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 16})
	buf := [u8(1), 2, 3, 4]
	b.write_bytes(0x0FFF, buf) or {
		expect_err_kind(err, .range)
		return
	}
	assert false, 'expected .range error'
}

fn test_fake_backend_read_before_attach() {
	mut b := FakeBackend{
		target_pid: 9
		base:       0x1000
		mem:        []u8{len: 8}
	}
	mut buf := []u8{len: 4}
	b.read_bytes(0x1000, mut buf) or {
		expect_err_kind(err, .not_attached)
		return
	}
	assert false, 'expected .not_attached error'
}

fn test_fake_backend_write_before_attach() {
	mut b := FakeBackend{
		target_pid: 9
		base:       0x1000
		mem:        []u8{len: 8}
	}
	buf := [u8(1), 2, 3, 4]
	b.write_bytes(0x1000, buf) or {
		expect_err_kind(err, .not_attached)
		return
	}
	assert false, 'expected .not_attached error'
}

fn test_fake_backend_read_after_detach() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 8})
	b.detach()!
	assert !b.attached
	mut buf := []u8{len: 4}
	b.read_bytes(0x1000, mut buf) or {
		expect_err_kind(err, .not_attached)
		return
	}
	assert false, 'expected .not_attached error'
}

fn test_fake_backend_write_after_detach() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 8})
	b.detach()!
	assert !b.attached
	buf := [u8(1), 2, 3, 4]
	b.write_bytes(0x1000, buf) or {
		expect_err_kind(err, .not_attached)
		return
	}
	assert false, 'expected .not_attached error'
}

fn test_fake_backend_enumerate_regions() {
	mut b := new_fake_backend(42, 0x2000, []u8{len: 64})
	rs := b.enumerate_regions() or { panic(err) }
	assert rs.len == 1
	assert rs[0].base == 0x2000
	assert rs[0].size == 64
	assert rs[0].prot == (prot_read | prot_write)
	assert rs[0].class == .c_alloc
	assert rs[0].name == '[fake]'
}

fn test_fake_backend_enumerate_modules() {
	mut b := new_fake_backend(42, 0x2000, []u8{len: 64})
	mods := b.enumerate_modules() or { panic(err) }
	assert mods.len == 1
	assert mods[0].base == 0x2000
	assert mods[0].size == 64
	assert mods[0].path == 'fake.bin'
	assert mods[0].name == 'fake.bin'
}

fn test_fake_backend_suspend_resume_kill() {
	mut b := new_fake_backend(42, 0x1000, []u8{len: 8})
	assert !b.suspended
	assert !b.killed
	b.suspend()!
	assert b.suspended
	b.resume()!
	assert !b.suspended
	b.kill()!
	assert b.killed
}

fn test_fake_backend_satisfies_memory_backend() {
	mut b := new_fake_backend(7, 0x4000, []u8{len: 16})
	assert backend_pid(mut b) == 7
	v := backend_roundtrip(mut b, 0x4008) or { panic(err) }
	assert v == 7
}
