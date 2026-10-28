module sys

import os

// enumerate_modules lists file-backed executable mappings grouped by path
// (base = lowest mapping, size = span).
pub fn enumerate_modules(h voidptr, mut sink ModuleSink) ! {
	pid := pid_from_handle(h)
	content := os.read_file('/proc/${pid}/maps') or {
		return error_with_code('enumerate_modules: ${err.msg()}', 0)
	}
	mut bases := map[string]u64{}
	mut ends := map[string]u64{}
	for line in content.split_into_lines() {
		parts := line.split_any(' \t')
		if parts.len < 2 || !parts[1].contains('x') {
			continue
		}
		path := line.all_after_last(' ')
		if !path.starts_with('/') {
			continue
		}
		rng := parts[0].split('-')
		if rng.len != 2 {
			continue
		}
		base := hex_u64(rng[0])
		end := hex_u64(rng[1])
		if path !in bases || base < bases[path] {
			bases[path] = base
		}
		if path !in ends || end > ends[path] {
			ends[path] = end
		}
	}
	for path, base in bases {
		sink.push(base, ends[path] - base, path)
	}
}
