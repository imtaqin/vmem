module sys

// enumerate_regions walks the target VA space via VirtualQueryEx and pushes
// every region (free/reserve/commit) with normalized prot/kind bits.
pub fn enumerate_regions(h voidptr, mut sink RegionSink) ! {
	mut addr := u64(0)
	for {
		mut m := MemBasicInfo{}
		r := C.VirtualQueryEx(h, voidptr(usize(addr)), voidptr(&m), usize(sizeof(MemBasicInfo)))
		if r == 0 {
			break
		}
		base := u64(usize(m.base_address))
		size := u64(m.region_size)
		prot := win_prot_to_bits(m.protect)
		kind := win_type_to_kind(m.type_)
		sink.push(base, size, m.state == win_mem_commit, prot, kind, '')
		next := base + size
		if next <= addr {
			break
		}
		addr = next
	}
}

// win_type_to_kind normalizes MEM_* type to sys.kind_* codes.
fn win_type_to_kind(t u32) u32 {
	match t {
		win_mem_image { return kind_image }
		win_mem_mapped { return kind_mapped }
		win_mem_private { return kind_private }
		else { return kind_other }
	}
}
