module vmem

// pid returns the attached target pid.
pub fn (b &LocalBackend) pid() int {
	return b.target_pid
}
