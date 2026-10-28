module vmem

// op_scan handles scan-execute (encoded ScanPlan) and returns an encoded hit list.
// The scan runs agent-side through the same engine semantics as scan_first.
fn (mut st ServeState) op_scan(payload []u8) ![]u8 {
	if !st.attached {
		return new_error(.not_attached, 'agent scan', 0)
	}
	plan := decode_scan_plan(payload) or { return wrap_err(.protocol, 'agent scan plan', err) }
	mut s := new_scan_session()
	scan_first(mut st.backend, mut s, plan) or {
		return wrap_err(.access_denied, 'agent scan', err)
	}
	return encode_hit_list(s.addresses, s.prev_raw, s.stable, s.stride)
}
