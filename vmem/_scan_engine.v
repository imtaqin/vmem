module vmem

// Internal shared scan collector (one concern; AGENTS.md §3).
// Walks the given regions and appends matching hits to the output arrays.
// Used by scan_first (session-owned arrays) and by parallel workers (their
// own arrays). limit<=0 means unlimited. Zero allocation in the compare
// loop; output arrays grow amortized.

fn scan_collect(mut backend MemoryBackend, regions []Region, plan ScanPlan, sz int, align u64, mut addresses []u64, mut prev_raw []u8, mut first_raw []u8, mut stable []u32, limit int) {
	mut reader := new_chunk_reader()
	zero := []u8{len: sz}
	for region in regions {
		if !region_in_scope(region, plan.filter) {
			continue
		}
		mut addr := align_up(region.base, align)
		if plan.filter.start > addr {
			addr = align_up(plan.filter.start, align)
		}
		mut end := region.base + region.size
		if plan.filter.end != 0 && plan.filter.end < end {
			end = plan.filter.end
		}
		for addr + u64(sz) <= end {
			ok := reader.ensure(mut backend, addr, sz) or {
				// unreadable page (guard/no-access): skip it, keep scanning
				addr = align_up(addr + 4096, align)
				continue
			}
			if !ok {
				addr = align_up(addr + 4096, align)
				continue
			}
			// scan everything covered by the current window
			wend := reader.win_start + u64(reader.win_valid)
			limit_addr := if wend < end { wend } else { end }
			mut a := addr
			for a + u64(sz) <= limit_addr {
				o := reader.off(a)
				cur := reader.buf[o..o + sz]
				if match_kind(plan.kind, plan.op, cur, zero, zero, plan) {
					addresses << a
					prev_raw << cur
					first_raw << cur
					stable << 1
					if limit > 0 && addresses.len >= limit {
						return
					}
				}
				a += align
			}
			if a == addr {
				break
			}
			addr = a
		}
	}
}
