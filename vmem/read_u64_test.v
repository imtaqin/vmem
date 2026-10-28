module vmem

fn test_read_u64_own_memory() {
	mut x := u64(0x1122334455667788)
	addr := u64(unsafe { usize(&x) })
	v := read_u64(current_pid(), addr) or { panic(err) }
	assert v == u64(0x1122334455667788)
	assert x == v // keep x alive
}
