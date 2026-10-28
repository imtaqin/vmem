module vmem

import vmem.sys.remote

// resume resumes the target through the agent.
pub fn (mut r RemoteBackend) resume() ! {
	r.rpc(remote.op_resume, []) or { return wrap_err(.access_denied, 'remote resume', err) }
}
