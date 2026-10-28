module vmem

fn test_write_u32_own_memory() {
	mut x := u32(0)
	addr := u64(unsafe { usize(&x) })
	n := write_u32(current_pid(), addr, u32(0xAABBCCDD)) or { panic(err) }
	assert n == 4
	assert x == u32(0xAABBCCDD)
	// restore so later asserts on x are deterministic
	x = u32(0)
	assert x == u32(0)
}
