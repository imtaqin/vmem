module vmem

import os

// save_list writes a saved list (GameGuardian-style text table):
// one row per line, `0xADDR<TAB>kind<TAB>value<TAB>name`.
// Returns rows written.
pub fn save_list(path string, entries []TableEntry) !int {
	mut f := os.create(path) or { return wrap_err(.access_denied, 'save_list create ${path}', err) }
	defer {
		f.close()
	}
	for e in entries {
		name := e.name.replace('\t', ' ').replace('\n', ' ')
		f.writeln('0x${e.address:x}\t${kind_name(e.kind)}\t${e.value}\t${name}') or {
			return wrap_err(.access_denied, 'save_list write', err)
		}
	}
	return entries.len
}
