module vmem

// FieldGuess is one dissected field candidate (heuristic type inference).
pub struct FieldGuess {
pub:
	offset int
	kind   ValueKind
	value  f64
	notes  string
}

// dissect_struct inspects size bytes at addr and guesses field types at
// 4-byte boundaries (heuristic; CE dissect starts from known fields — here
// the plausibility rules are: pointer-looking qwords, printable text runs,
// and plain scalars).
pub fn dissect_struct(mut backend MemoryBackend, addr u64, size int) ![]FieldGuess {
	if size <= 0 || size > 64 * 1024 {
		return new_error(.range, 'dissect_struct size=${size}', 0)
	}
	mut buf := []u8{len: size}
	n := backend.read_bytes(addr, mut buf) or {
		return wrap_err(.access_denied, 'dissect_struct 0x${addr:x}', err)
	}
	if n != size {
		return new_error(.short_io, 'dissect_struct got ${n}/${size}', 0)
	}
	regions := backend.enumerate_regions() or { []Region{} }
	mut out := []FieldGuess{}
	mut off := 0
	for off + 4 <= size {
		mut q := u64(0)
		if off + 8 <= size {
			q = decode_u64_le(buf[off..off + 8])
		}
		mut notes := ''
		mut kind := ValueKind.dword
		mut value := f64(0)
		if q > u64(0x10000) && q < u64(0x800000000000) && in_any_region(regions, q) {
			kind = .qword
			value = f64(q)
			notes = 'ptr'
		} else {
			d := decode_u32_le(buf[off..off + 4])
			kind = .dword
			value = f64(i64(i32(d)))
			if is_text_run(buf[off..if off + 8 <= size { off + 8 } else { size }]) {
				notes = 'text?'
			}
		}
		out << FieldGuess{
			offset: off
			kind:   kind
			value:  value
			notes:  notes
		}
		off += 4
	}
	return out
}

fn in_any_region(regions []Region, v u64) bool {
	for r in regions {
		if v >= r.base && v < r.base + r.size {
			return true
		}
	}
	return false
}

fn is_text_run(b []u8) bool {
	mut printable := 0
	for c in b {
		if c >= 0x20 && c < 0x7F {
			printable++
		}
	}
	return printable >= 4
}
