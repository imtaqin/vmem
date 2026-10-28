module vmem

// freeze_tick runs one rewrite pass over the list:
//   .normal       always write value
//   .may_increase write value only when the current value dropped below it
//   .may_decrease write value only when the current value rose above it
//   .in_range     clamp into [from, to]
// Returns the number of writes performed.
pub fn freeze_tick(mut backend MemoryBackend, mut f FreezeList) !int {
	mut writes := 0
	for i in 0 .. f.entries.len {
		mut e := f.entries[i]
		sz := kind_size(e.kind)
		if sz == 0 {
			continue
		}
		mut buf := []u8{len: sz}
		n := backend.read_bytes(e.addr, mut buf) or { continue }
		if n != sz {
			continue
		}
		cur := decode_kind_num(e.kind, buf)
		mut want := e.value
		mut do_write := true
		match e.mode {
			.normal {}
			.may_increase {
				do_write = cur < e.value
			}
			.may_decrease {
				do_write = cur > e.value
			}
			.in_range {
				if cur < e.from {
					want = e.from
				} else if cur > e.to {
					want = e.to
				} else {
					do_write = false
				}
			}
		}

		if do_write {
			edit_value(mut backend, e.kind, e.addr, want) or { continue }
			e.writes++
			f.entries[i] = e
			writes++
		}
	}
	return writes
}
