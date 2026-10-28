module vmem

import vmem.sys.remote
import net

// serve_remote_conn runs the agent-side protocol over one connection:
// version handshake, then request dispatch until the peer disconnects.
// agent/main.v wraps this with a TCP listener; tests use it in-process
// (AGENTS.md §2).
pub fn serve_remote_conn(mut c net.TcpConn) ! {
	strintp_keepalive() // see _strintp_workaround.v (vlib net str() chain)
	f := remote.recv_frame(mut c) or { return wrap_err(.transport, 'serve handshake', err) }
	if f.opcode != remote.op_hello {
		bad := wire_error(new_error(.protocol, 'expected hello, got ${f.opcode}', 0))
		remote.send_frame(mut c, remote.op_error, remote.flag_response, f.request_id, bad) or {}
		return new_error(.protocol, 'expected hello, got ${f.opcode}', 0)
	}
	ack := [u8(remote.proto_version), 0]
	remote.send_frame(mut c, remote.op_hello_ack, remote.flag_response, f.request_id, ack) or {
		return wrap_err(.transport, 'serve hello ack', err)
	}
	mut st := ServeState{}
	for {
		fr := remote.recv_frame(mut c) or { return } // peer closed or link lost
		mut payload := []u8{}
		mut failed := false
		match fr.opcode {
			remote.op_attach {
				payload = st.op_attach(fr.payload) or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_detach {
				payload = st.op_detach() or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_read {
				payload = st.op_read(fr.payload) or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_write {
				payload = st.op_write(fr.payload) or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_regions {
				payload = st.op_regions() or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_modules {
				payload = st.op_modules() or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_processes {
				payload = st.op_processes() or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_suspend {
				payload = st.op_suspend() or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_resume {
				payload = st.op_resume() or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_kill {
				payload = st.op_kill() or {
					failed = true
					wire_error(err)
				}
			}
			remote.op_scan_execute {
				payload = st.op_scan(fr.payload) or {
					failed = true
					wire_error(err)
				}
			}
			else {
				failed = true
				payload = wire_error(new_error(.protocol, 'unknown opcode ${fr.opcode}', 0))
			}
		}

		op := if failed { remote.op_error } else { fr.opcode | remote.flag_response }
		remote.send_frame(mut c, op, remote.flag_response, fr.request_id, payload) or {
			return wrap_err(.transport, 'serve reply op=${fr.opcode}', err)
		}
	}
}
