module vmem

// RegionCollector implements vmem/sys RegionSink into domain Regions.
struct RegionCollector {
mut:
	out []Region
}

fn (mut c RegionCollector) push(base u64, size u64, committed bool, prot u32, kind u32, name string) {
	if !committed || size == 0 {
		return
	}
	c.out << Region{
		base:  base
		size:  size
		prot:  prot
		class: classify_region(prot, kind, name)
		name:  name
	}
}
