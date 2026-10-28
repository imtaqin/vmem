module vmem

import os

// dump_memory writes the raw bytes of [start, end) to path, chunked.
// Unreadable pages are written as zeros so file offsets stay address-stable.
// Returns the number of bytes written.
pub fn dump_memory(mut backend MemoryBackend, path string, start u64, end u64) !int {
	if end <= start {
		return new_error(.range, 'dump_memory end=0x${end:x} <= start=0x${start:x}', 0)
	}
	mut f := os.create(path) or {
		return wrap_err(.access_denied, 'dump_memory create ${path}', err)
	}
	defer {
		f.close()
	}
	mut reader := new_chunk_reader()
	mut addr := start
	mut total := 0
	zeros := []u8{len: scan_window}
	for addr < end {
		mut want := scan_window
		if u64(want) > end - addr {
			want = int(end - addr)
		}
		ok := reader.ensure(mut backend, addr, 1) or { false }
		if ok && reader.win_start == addr && reader.win_valid > 0 {
			n := if want > reader.win_valid { reader.win_valid } else { want }
			f.write(reader.buf[0..n]) or {
				return wrap_err(.access_denied, 'dump_memory write', err)
			}
			total += n
			addr += u64(n)
		} else {
			f.write(zeros[0..want]) or { return wrap_err(.access_denied, 'dump_memory write', err) }
			total += want
			addr += u64(want)
		}
	}
	return total
}
