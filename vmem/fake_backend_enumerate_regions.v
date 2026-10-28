module vmem

// enumerate_regions reports the single fake mapping.
pub fn (mut b FakeBackend) enumerate_regions() ![]Region {
	return [
		Region{
			base:  b.base
			size:  u64(b.mem.len)
			prot:  prot_read | prot_write
			class: .c_alloc
			name:  '[fake]'
		},
	]
}
