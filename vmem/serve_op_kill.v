module vmem

// op_kill handles the kill operation.
fn (mut st ServeState) op_kill() ![]u8 {
	if !st.attached {
		return new_error(.not_attached, 'agent kill', 0)
	}
	st.backend.kill() or { return wrap_err(.access_denied, 'agent kill', err) }
	st.attached = false
	return []u8{}
}
