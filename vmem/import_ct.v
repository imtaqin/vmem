module vmem

import os

// import_ct parses a Cheat Engine .CT table subset: every <CheatEntry>'s
// <Address> (hex or module+offset), <Description>, <VariableType>.
// Entries whose address is not plain hex are kept with base 0 and their raw
// text in name (CE pointer/script rows are out of scope).
// Returns the parsed rows.
pub fn import_ct(path string) ![]TableEntry {
	content := os.read_file(path) or {
		return wrap_err(.access_denied, 'import_ct read ${path}', err)
	}
	mut out := []TableEntry{}
	mut rest := content
	for {
		open := rest.index('<CheatEntry>') or { break }
		close_idx := rest.index('</CheatEntry>') or { break }
		block := rest[open + 11..close_idx]
		rest = rest[close_idx + 13..]
		mut addr := u64(0)
		mut name := ''
		mut kind := ValueKind.dword
		if a := xml_tag(block, 'Address') {
			clean := a.trim_space().trim_left('0xX')
			if clean.len > 0 && is_hex_nibbles(clean) {
				addr = hex_u64(clean)
			} else {
				name = a.trim_space()
			}
		}
		if d := xml_tag(block, 'Description') {
			if name == '' {
				name = d
			}
		}
		if v := xml_tag(block, 'VariableType') {
			k := kind_from_name(v) or { ValueKind.dword }
			kind = k
		}
		out << TableEntry{
			address: addr
			kind:    kind
			name:    name
		}
	}
	return out
}

// xml_tag extracts the text between the first <tag> and </tag>.
fn xml_tag(block string, tag string) ?string {
	start := block.index('<${tag}>') or { return none }
	after := start + tag.len + 2
	end := block.index('</${tag}>') or { return none }
	if end < after {
		return none
	}
	return block[after..end]
}
