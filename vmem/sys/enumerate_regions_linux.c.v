module sys

import os

// enumerate_regions parses /proc/<pid>/maps and pushes normalized rows.
pub fn enumerate_regions(h voidptr, mut sink RegionSink) ! {
	pid := pid_from_handle(h)
	content := os.read_file('/proc/${pid}/maps') or {
		return error_with_code('enumerate_regions: ${err.msg()}', 0)
	}
	for line in content.split_into_lines() {
		parts := line.split_any(' \t')
		if parts.len < 2 {
			continue
		}
		rng := parts[0].split('-')
		if rng.len != 2 {
			continue
		}
		base := hex_u64(rng[0])
		end := hex_u64(rng[1])
		perms := parts[1]
		mut prot := u32(0)
		if perms.len > 0 && perms[0] == `r` {
			prot |= prot_read
		}
		if perms.len > 1 && perms[1] == `w` {
			prot |= prot_write
		}
		if perms.len > 2 && perms[2] == `x` {
			prot |= prot_exec
		}
		if perms.len > 3 && perms[3] == `s` {
			prot |= prot_cow
		}
		mut name := ''
		if parts.len >= 6 {
			name = line.all_after_last(' ')
		}
		kind := if name.starts_with('/') { kind_image } else { kind_private }
		sink.push(base, end - base, true, prot, kind, name)
	}
}

// hex_u64 parses a lowercase hex string (maps addresses).
fn hex_u64(s string) u64 {
	mut v := u64(0)
	for i in 0 .. s.len {
		c := s[i]
		mut n := 0
		if c >= `0` && c <= `9` {
			n = int(c - `0`)
		} else if c >= `a` && c <= `f` {
			n = int(c - `a`) + 10
		} else {
			return v
		}
		v = v * 16 + u64(n)
	}
	return v
}
