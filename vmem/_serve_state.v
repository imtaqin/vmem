module vmem

// ServeState is the per-connection agent state: one LocalBackend target.
struct ServeState {
mut:
	backend  LocalBackend
	attached bool
}
