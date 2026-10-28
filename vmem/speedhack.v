module vmem

// Speedhack state: GetTickCount is detoured to a cave that returns a
// host-driven virtual clock (see speedhack_install/speedhack_tick).
pub struct Speedhack {
pub mut:
	hook         Hook
	page         u64
	data_addr    u64
	factor       f64
	real_elapsed u64
	virtual_now  u64
}
