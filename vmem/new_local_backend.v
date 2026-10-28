module vmem

// new_local_backend attaches to pid and returns a ready backend.
pub fn new_local_backend(pid int) !LocalBackend {
	mut b := LocalBackend{}
	b.attach(pid)!
	return b
}
