module vmem

// speedhack_tick advances the virtual clock by real_elapsed_ms * factor and
// publishes it to the cave slot. Drive it from a ticker (freeze_run-style).
pub fn speedhack_tick(mut b LocalBackend, mut s Speedhack, real_elapsed_ms u64) ! {
	s.real_elapsed += real_elapsed_ms
	s.virtual_now += u64(f64(real_elapsed_ms) * s.factor)
	mut slot := []u8{len: 8}
	encode_u64_le(s.virtual_now, mut slot)
	patch_bytes(mut b, s.data_addr, slot) or {
		return wrap_err(.access_denied, 'speedhack_tick write', err)
	}
}
