module sys

// Sink interfaces let sys push enumerated facts without allocating
// domain types or sharing structs upward (layering: AGENTS.md §2).
// Only builtin types cross the boundary.
//
// RegionSink.push:
//   committed — the range is committed/mapped (vs reserved/free)
//   prot      — sys.prot_* bits (normalized per OS)
//   kind      — sys.kind_* codes (normalized per OS)

pub interface ProcessSink {
	push(pid int, name string, path string)
}

pub interface RegionSink {
	push(base u64, size u64, committed bool, prot u32, kind u32, name string)
}

pub interface ModuleSink {
	push(base u64, size u64, path string)
}

pub interface ThreadSink {
	push(tid int)
}
