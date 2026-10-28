module vmem

// edit_value writes one value (kind width, little-endian) at addr.
// Returns bytes written (kind width) or a short_io error.
pub fn edit_value(mut backend MemoryBackend, kind ValueKind, addr u64, value f64) !int {
	sz := kind_size(kind)
	if sz == 0 {
		return new_error(.unsupported, 'edit kind ${kind}', 0)
	}
	mut buf := []u8{len: sz}
	encode_kind_value(kind, value, mut buf)
	n := backend.write_bytes(addr, buf) or {
		return wrap_err(.access_denied, 'edit_value 0x${addr:x}', err)
	}
	if n != sz {
		return new_error(.short_io, 'edit_value 0x${addr:x} got=${n}/${sz}', 0)
	}
	return n
}
