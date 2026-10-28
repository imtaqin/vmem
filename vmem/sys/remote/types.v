module remote

// Wire protocol v1 types and constants (docs/PLATFORM-API.md §4.4).
// Frame: u32 total | u16 opcode | u16 flags | u64 request_id | payload,
// little-endian. total = 2+2+8+payload.len (bytes after the length field).
// Responses reuse the request opcode with flag_response set; ERROR (255)
// carries a code and message.

pub const proto_version = u16(1)
pub const flag_response = u16(0x8000)

pub const op_hello = u16(1)
pub const op_hello_ack = u16(2)
pub const op_attach = u16(10)
pub const op_detach = u16(11)
pub const op_read = u16(20)
pub const op_write = u16(21)
pub const op_regions = u16(22)
pub const op_modules = u16(23)
pub const op_processes = u16(24)
pub const op_suspend = u16(25)
pub const op_resume = u16(26)
pub const op_kill = u16(27)
pub const op_scan_execute = u16(30)
pub const op_error = u16(255)

pub const max_payload = 16 * 1024 * 1024

// Frame is one decoded wire message.
pub struct Frame {
pub:
	opcode     u16
	flags      u16
	request_id u64
	payload    []u8
}
