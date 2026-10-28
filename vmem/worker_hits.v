module vmem

// WorkerHits is one parallel worker's collected scan hits (internal).
struct WorkerHits {
mut:
	addresses []u64
	prev_raw  []u8
	first_raw []u8
	stable    []u32
}
