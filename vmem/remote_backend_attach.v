module vmem

import vmem.sys.remote

// attach selects the target pid on the agent.
pub fn (mut r RemoteBackend) attach(pid int) ! {
	mut p := []u8{len: 4}
	p[0] = u8(u32(pid))
	p[1] = u8(u32(pid) >> 8)
	p[2] = u8(u32(pid) >> 16)
	p[3] = u8(u32(pid) >> 24)
	r.rpc(remote.op_attach, p) or {
		return wrap_err(.access_denied, 'remote attach pid=${pid}', err)
	}
	r.target_pid = pid
	r.attached = true
}
