module vmem

// FreezeList holds the frozen entries of one session; drive it by calling
// freeze_tick periodically (freeze_run does that for a duration).
// Thread-safety: one list per ticker thread (AGENTS.md §4).
pub struct FreezeList {
pub mut:
	entries []FreezeEntry
	period  int = 100 // default rewrite period in ms (~10 Hz)
}
