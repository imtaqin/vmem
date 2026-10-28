module vmem

// Workaround: V's auto-`str()` for vlib structs (net.TcpConn chain) emits
// uses of StrIntpData and builtin__str_intp without registering them, so
// skip-unused builds drop the declarations (C: "implicit declaration" then
// parse errors). This live fn marks the family used; version() and net entry
// points call it. Remove when upstream is fixed.
@[markused]
pub struct StrIntpKeepalive {
pub:
	keep StrIntpData
}

// strintp_keepalive keeps the StrIntpData type registered (file comment).
@[markused]
pub fn strintp_keepalive() {
	_ := StrIntpKeepalive{}
	mut s := str_intp(0, unsafe { nil })
	s = s.replace('x', 'y')
	_ := s.repeat(2)
	unsafe {
		s.free()
	}
}
