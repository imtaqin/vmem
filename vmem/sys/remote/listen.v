module remote

import net

// listen opens the agent-side TCP listener (loopback by default).
pub fn listen(host string, port int) !&net.TcpListener {
	l := net.listen_tcp(.ip, '${host}:${port}', net.ListenOptions{}) or {
		return error_with_code('remote listen ${host}:${port}: ${err.msg()}', err.code())
	}
	return l
}
