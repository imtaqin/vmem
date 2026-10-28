module vmem

import vmem.sys.remote

// enumerate_modules lists the agent-side target modules.
pub fn (mut r RemoteBackend) enumerate_modules() ![]ModuleInfo {
	resp := r.rpc(remote.op_modules, []) or {
		return wrap_err(.access_denied, 'remote enumerate_modules', err)
	}
	mut out := []ModuleInfo{}
	if resp.len < 4 {
		return out
	}
	count := int(decode_u32_le(resp[0..4]))
	mut i := 4
	for _ in 0 .. count {
		if i + 18 > resp.len {
			return new_error(.protocol, 'remote modules: truncated', 0)
		}
		base := decode_u64_le(resp[i..i + 8])
		size := decode_u64_le(resp[i + 8..i + 16])
		i += 16
		path, ni := wire_read_str(resp, i)
		i = ni
		mut name := path
		mut cut := -1
		if k := path.last_index('/') {
			cut = k
		}
		if k := path.last_index('\\') {
			if k > cut {
				cut = k
			}
		}
		if cut >= 0 {
			name = path[cut + 1..]
		}
		out << ModuleInfo{
			base: base
			size: size
			path: path
			name: name
		}
	}
	return out
}
