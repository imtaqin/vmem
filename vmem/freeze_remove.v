module vmem

// freeze_remove drops the entry at index i (no-op when out of range).
pub fn freeze_remove(mut f FreezeList, i int) {
	if i < 0 || i >= f.entries.len {
		return
	}
	f.entries.delete(i)
}
