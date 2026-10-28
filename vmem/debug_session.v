module vmem

// DebugSession is an external debugging session (debug-API model).
// Breakpoints live in the hardware debug registers of every target thread.
// Thread-safety: one session per debugger thread (AGENTS.md §4).
pub struct DebugSession {
mut:
	pid      int
	handle   voidptr
	attached bool
	slots    [4]u64
	in_use   [4]bool
}
