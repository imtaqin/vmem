module vmem

// op_suspend handles the suspend operation.
fn (mut st ServeState) op_suspend() ![]u8 {
	if !st.attached {
		return new_error(.not_attached, 'agent suspend', 0)
	}
	st.backend.suspend() or { return wrap_err(.access_denied, 'agent suspend', err) }
	return []u8{}
}
