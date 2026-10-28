module vmem

// enumerate_modules reports the single fake image.
pub fn (mut b FakeBackend) enumerate_modules() ![]ModuleInfo {
	return [
		ModuleInfo{
			base: b.base
			size: u64(b.mem.len)
			path: 'fake.bin'
			name: 'fake.bin'
		},
	]
}
