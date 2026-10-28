module vmem

import vmem.sys.remote

// enumerate_regions lists the agent-side target regions.
pub fn (mut r RemoteBackend) enumerate_regions() ![]Region {
	resp := r.rpc(remote.op_regions, []) or {
		return wrap_err(.access_denied, 'remote enumerate_regions', err)
	}
	mut out := []Region{}
	if resp.len < 4 {
		return out
	}
	count := int(decode_u32_le(resp[0..4]))
	mut i := 4
	for _ in 0 .. count {
		if i + 26 > resp.len {
			return new_error(.protocol, 'remote regions: truncated', 0)
		}
		base := decode_u64_le(resp[i..i + 8])
		size := decode_u64_le(resp[i + 8..i + 16])
		prot := decode_u32_le(resp[i + 16..i + 20])
		class := decode_u32_le(resp[i + 20..i + 24])
		nlen := int(decode_u16_le(resp[i + 24..i + 26]))
		i += 26
		if i + nlen > resp.len {
			return new_error(.protocol, 'remote regions: truncated name', 0)
		}
		name := resp[i..i + nlen].bytestr()
		i += nlen
		out << Region{
			base:  base
			size:  size
			prot:  prot
			class: unsafe { RegionClass(class) }
			name:  name
		}
	}
	return out
}
