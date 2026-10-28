module vmem

import vmem.sys.remote

// detach releases the target on the agent (safe to repeat).
pub fn (mut r RemoteBackend) detach() ! {
	if r.attached {
		r.rpc(remote.op_detach, []) or {}
		r.attached = false
	}
}
