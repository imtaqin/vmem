module vmem

// Internal sequential window reader (one concern; AGENTS.md §3).
// Fills one reusable buffer with a window of target memory so scan passes
// issue chunked reads instead of per-hit syscalls. When a window read fails
// (short mapping, region end, permissions) the request halves until it is
// just the needed size, then gives up. Zero allocation after construction.

const scan_window = 64 * 1024

struct ChunkReader {
mut:
	buf        []u8
	win_start  u64
	win_valid  int
	has_window bool
}

fn new_chunk_reader() ChunkReader {
	return ChunkReader{
		buf: []u8{len: scan_window}
	}
}

// ensure makes [addr, addr+need) readable through r.buf; it re-reads only
// when the request falls outside the current window. Returns false when no
// request size can cover need bytes (caller moves to the next region/hit).
fn (mut r ChunkReader) ensure(mut backend MemoryBackend, addr u64, need int) !bool {
	if r.has_window && addr >= r.win_start && addr + u64(need) <= r.win_start + u64(r.win_valid) {
		return true
	}
	mut req := scan_window
	for req >= need {
		n := backend.read_bytes(addr, mut r.buf[0..req]) or {
			req /= 2
			continue
		}
		r.win_start = addr
		r.win_valid = n
		r.has_window = true
		return n >= need
	}
	return false
}

// off converts an absolute address to an offset inside the current window.
fn (r &ChunkReader) off(addr u64) int {
	return int(addr - r.win_start)
}
