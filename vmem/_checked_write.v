module vmem

// checked_write is the shared tail of the typed write helpers: it writes
// buf and errors when the write is short (one concern; AGENTS.md §3).
fn checked_write(pid int, addr u64, buf []u8, want int, op string) !int {
	n := write_bytes(pid, addr, buf)!
	if n != want {
		return new_error(.short_io, '${op} addr=0x${addr:x} got=${n}/${want}', 0)
	}
	return n
}
