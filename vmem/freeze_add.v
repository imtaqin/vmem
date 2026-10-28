module vmem

// freeze_add appends a frozen entry and returns its index.
// For .in_range, from/to bound the kept value; otherwise value is the point.
pub fn freeze_add(mut f FreezeList, addr u64, kind ValueKind, value f64, from f64, to f64, mode FreezeMode) int {
	f.entries << FreezeEntry{
		addr:  addr
		kind:  kind
		value: value
		from:  from
		to:    to
		mode:  mode
	}
	return f.entries.len - 1
}
