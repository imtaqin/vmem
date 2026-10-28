module vmem

// pid returns the attached target pid (agent-side).
pub fn (r &RemoteBackend) pid() int {
	return r.target_pid
}
