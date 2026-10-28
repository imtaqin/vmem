module vmem

import time

// freeze_run drives freeze_tick at the list period for duration_ms
// (0 = one tick). Returns the total number of writes.
pub fn freeze_run(mut backend MemoryBackend, mut f FreezeList, duration_ms int) !int {
	mut total := 0
	deadline := time.ticks() + i64(duration_ms)
	for {
		total += freeze_tick(mut backend, mut f) or { 0 }
		if duration_ms <= 0 || time.ticks() >= deadline {
			break
		}
		time.sleep(f.period * time.millisecond)
	}
	return total
}
