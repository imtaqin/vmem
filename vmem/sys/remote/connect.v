module remote

import net

// connect opens a TCP connection to a device agent (adb-forwarded or LAN).
pub fn connect(host string, port int) !&net.TcpConn {
	c := net.dial_tcp('${host}:${port}') or {
		return error_with_code('remote connect ${host}:${port}: ${err.msg()}', err.code())
	}
	return c
}
