module vmem

// op_detach handles the detach operation.
fn (mut st ServeState) op_detach() ![]u8 {
	if st.attached {
		st.backend.detach() or {}
		st.attached = false
	}
	return []u8{}
}
