module vmem

import os

// load_list parses the text format written by save_list (also tolerant of
// GameGuardian-style rows: `0xADDR value kind`). Blank lines and `#` lines
// are skipped. Returns the parsed rows.
pub fn load_list(path string) ![]TableEntry {
	content := os.read_file(path) or {
		return wrap_err(.access_denied, 'load_list read ${path}', err)
	}
	mut out := []TableEntry{}
	for line in content.split_into_lines() {
		t := line.trim_space()
		if t == '' || t.starts_with('#') {
			continue
		}
		parts := t.split('\t')
		mut addr_s := ''
		mut kind_s := ''
		mut val_s := ''
		mut name := ''
		if parts.len >= 3 {
			addr_s = parts[0]
			kind_s = parts[1]
			val_s = parts[2]
			if parts.len >= 4 {
				name = parts[3]
			}
		} else {
			// GG-style whitespace rows: addr value kind
			ws := t.split(' ')
			if ws.len < 3 {
				continue
			}
			addr_s = ws[0]
			val_s = ws[1]
			kind_s = ws[2]
		}
		addr := hex_u64(addr_s.trim_space().trim_left('0xX'))
		kind := kind_from_name(kind_s.trim_space()) or { continue }
		out << TableEntry{
			address: addr
			kind:    kind
			value:   val_s.trim_space().f64()
			name:    name
		}
	}
	return out
}
