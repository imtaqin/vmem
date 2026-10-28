module vmem

import net

// RemoteBackend drives a device agent over the wire protocol
// (docs/PLATFORM-API.md §4). It implements MemoryBackend and additionally
// offers scan_execute for agent-side scan offload.
// Thread-safety: one backend per thread (one RPC at a time per connection).
pub struct RemoteBackend {
mut:
	conn       &net.TcpConn = unsafe { nil }
	next_id    u64
	target_pid int
	attached   bool
}
