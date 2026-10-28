module vmem

import os

// dump_hex writes a classic hex-view text dump of [start, end) to path:
// `ADDRESS: bb bb ... |ascii|` per line, bytes_per_line bytes (0 = 16).
// Unreadable bytes render as zeros. Returns the number of source bytes dumped.
pub fn dump_hex(mut backend MemoryBackend, path string, start u64, end u64, bytes_per_line int) !int {
	if end <= start {
		return new_error(.range, 'dump_hex end=0x${end:x} <= start=0x${start:x}', 0)
	}
	per := if bytes_per_line <= 0 { 16 } else { bytes_per_line }
	mut f := os.create(path) or { return wrap_err(.access_denied, 'dump_hex create ${path}', err) }
	defer {
		f.close()
	}
	mut reader := new_chunk_reader()
	mut line := []u8{len: per}
	mut addr := start
	mut total := 0
	for addr < end {
		ok := reader.ensure(mut backend, addr, 1) or { false }
		avail := if ok && reader.win_start == addr { reader.win_valid } else { 0 }
		for i in 0 .. per {
			line[i] = if i < avail { reader.buf[i] } else { u8(0) }
		}
		mut txt := ''
		for b in line {
			txt += '${b:02x} '
		}
		mut ascii := ''
		for b in line {
			ascii += if b >= 0x20 && b < 0x7F { b.ascii_str() } else { '.' }
		}
		f.writeln('${addr:x}: ${txt} |${ascii}|') or {
			return wrap_err(.access_denied, 'dump_hex write', err)
		}
		total += per
		addr += u64(per)
	}
	return total
}
