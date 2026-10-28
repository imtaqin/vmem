module vmem

// ErrKind classifies failures for programmatic handling.
pub enum ErrKind {
	access_denied
	process_gone
	not_attached
	short_io
	unsupported
	transport
	protocol
	bad_pattern
	range
	state
}

// VmError is the single error type of the public API (AGENTS.md §4):
// it preserves the raw OS error code when one exists.
// NOTE: the two IError methods live here with the type by convention;
// this file is a declarations file.
pub struct VmError {
pub:
	kind    ErrKind
	detail  string
	os_code int
}

// msg returns the formatted error message.
pub fn (e VmError) msg() string {
	base := '${e.kind}: ${e.detail}'
	if e.os_code != 0 {
		return '${base} (os=${e.os_code})'
	}
	return base
}

// code returns the taxonomy ordinal of the error.
pub fn (e VmError) code() int {
	return int(e.kind) + 1
}
