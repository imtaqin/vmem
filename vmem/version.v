module vmem

// version is the library version (semver).
pub fn version() string {
	strintp_keepalive() // see _strintp_workaround.v
	return '0.1.0'
}
