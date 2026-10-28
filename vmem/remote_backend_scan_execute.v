module vmem

import vmem.sys.remote

// scan_execute runs the ScanPlan agent-side (offload) and fills the session
// with the returned hits. Semantics are identical to scan_first over bulk
// reads (P3 acceptance compares both paths).
pub fn (mut r RemoteBackend) scan_execute(plan ScanPlan, mut s ScanSession) !int {
	payload := encode_scan_plan(plan)
	resp := r.rpc(remote.op_scan_execute, payload) or {
		return wrap_err(.access_denied, 'remote scan_execute', err)
	}
	hits := decode_hit_list(resp) or { return wrap_err(.protocol, 'remote scan_execute hits', err) }
	s.kind = plan.kind
	s.op = plan.op
	s.align = if plan.align == 0 { u64(1) } else { plan.align }
	s.stride = hits.stride
	s.pattern = plan.pattern
	s.addresses = hits.addresses
	s.prev_raw = hits.raw
	s.first_raw = hits.raw.clone()
	s.stable = hits.stable
	s.total_hits = hits.addresses.len
	s.scans = 1
	return hits.addresses.len
}
