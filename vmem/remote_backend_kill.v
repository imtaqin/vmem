module vmem

import vmem.sys.remote

// kill terminates the target through the agent.
pub fn (mut r RemoteBackend) kill() ! {
	r.rpc(remote.op_kill, []) or { return wrap_err(.access_denied, 'remote kill', err) }
}
