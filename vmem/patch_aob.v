module vmem

// patch_aob finds the pattern in [start, end) and overwrites `offset` bytes
// into each hit with replacement (AOB injection model). Returns the number
// of hits patched (limit<=0 = all).
pub fn patch_aob(mut backend MemoryBackend, start u64, end u64, spec string, replacement []u8, offset int, limit int) !int {
	pat := parse_aob(spec) or { return wrap_err(.bad_pattern, 'patch_aob "${spec}"', err) }
	plan := ScanPlan{
		kind:    .aob
		op:      .eq
		pattern: pat
		filter:  ScanFilter{
			start: start
			end:   end
		}
	}
	mut s := new_scan_session()
	scan_first(mut backend, mut s, plan) or {
		return wrap_err(.access_denied, 'patch_aob scan', err)
	}
	mut count := 0
	for addr in s.addresses {
		patch_bytes(mut backend, addr + u64(offset), replacement) or { continue }
		count++
		if limit > 0 && count >= limit {
			break
		}
	}
	return count
}
