module vmem

// new_error builds a VmError; os_code is 0 when no OS error applies.
pub fn new_error(kind ErrKind, detail string, os_code int) VmError {
	return VmError{
		kind:    kind
		detail:  detail
		os_code: os_code
	}
}
