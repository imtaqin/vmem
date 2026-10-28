module vmem

// op_resume handles the resume operation.
fn (mut st ServeState) op_resume() ![]u8 {
	if !st.attached {
		return new_error(.not_attached, 'agent resume', 0)
	}
	st.backend.resume() or { return wrap_err(.access_denied, 'agent resume', err) }
	return []u8{}
}
