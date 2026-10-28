module vmem

// wrap_err converts a sys-layer error into the public VmError taxonomy.
pub fn wrap_err(kind ErrKind, op string, err IError) VmError {
	return new_error(kind, '${op}: ${err.msg()}', err.code())
}
