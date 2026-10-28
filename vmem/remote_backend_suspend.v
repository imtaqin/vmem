module vmem

import vmem.sys.remote

// suspend pauses the target through the agent.
pub fn (mut r RemoteBackend) suspend() ! {
	r.rpc(remote.op_suspend, []) or { return wrap_err(.access_denied, 'remote suspend', err) }
}
