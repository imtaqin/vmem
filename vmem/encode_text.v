module vmem

// encode_text returns the byte encoding of s for text scans/edits.
pub fn encode_text(s string, enc TextEncoding) []u8 {
	match enc {
		.ascii {
			return s.bytes()
		}
		.utf8 {
			return s.bytes()
		} // V strings are UTF-8 already
		.utf16le, .utf16be {
			mut out := []u8{}
			for r in s.runes() {
				c := u32(r)
				if c <= 0xFFFF {
					if enc == .utf16le {
						out << u8(c & 0xFF)
						out << u8((c >> 8) & 0xFF)
					} else {
						out << u8((c >> 8) & 0xFF)
						out << u8(c & 0xFF)
					}
				} else {
					// surrogate pair
					v := c - 0x10000
					hi := u16(0xD800 + (v >> 10))
					lo := u16(0xDC00 + (v & 0x3FF))
					if enc == .utf16le {
						out << u8(hi & 0xFF)
						out << u8((hi >> 8) & 0xFF)
						out << u8(lo & 0xFF)
						out << u8((lo >> 8) & 0xFF)
					} else {
						out << u8((hi >> 8) & 0xFF)
						out << u8(hi & 0xFF)
						out << u8((lo >> 8) & 0xFF)
						out << u8(lo & 0xFF)
					}
				}
			}
			return out
		}
	}
}
