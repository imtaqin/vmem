module vmem

import vmem.sys

// classify_region derives the GameGuardian-style class from normalized
// region facts. Heuristics are coarse on desktop OS (see PLATFORM-API).
pub fn classify_region(prot u32, kind u32, name string) RegionClass {
	lname := name.to_lower()
	if kind == sys.kind_image {
		if prot & prot_exec != 0 {
			if lname.starts_with('\\windows') || lname.starts_with('/system')
				|| lname.starts_with('/apex') || lname.starts_with('/vendor') {
				return .code_sys
			}
			return .code_app
		}
		return .c_data
	}
	if lname == '[stack]' || lname.starts_with('[stack') {
		return .stack
	}
	if lname.starts_with('[anon:.bss]') {
		return .c_bss
	}
	if lname == '[heap]' {
		return .c_heap
	}
	if kind == sys.kind_private {
		return .c_alloc
	}
	if kind == sys.kind_mapped {
		if lname.starts_with('/dev/ashmem') || lname.starts_with('/memfd:') {
			return .ashmem
		}
		if lname == '' {
			return .anonymous
		}
		return .other
	}
	return .other
}
