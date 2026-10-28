module vmem

// kind_from_name parses a kind_name (also accepts CE-style width names).
pub fn kind_from_name(s string) ?ValueKind {
	match s.to_lower() {
		'byte', '1', '1 byte' { return .byte }
		'word', '2', '2 bytes' { return .word }
		'dword', '4', '4 bytes' { return .dword }
		'qword', '8', '8 bytes' { return .qword }
		'float' { return .float }
		'double' { return .double }
		'text', 'string' { return .text }
		'aob' { return .aob }
		'encrypted', 'xor' { return .encrypted }
		'auto' { return .auto }
		else { return none }
	}
}
