module vmem

// kind_name returns the table-format name of a ValueKind.
pub fn kind_name(k ValueKind) string {
	match k {
		.byte { return 'byte' }
		.word { return 'word' }
		.dword { return 'dword' }
		.qword { return 'qword' }
		.float { return 'float' }
		.double { return 'double' }
		.text { return 'text' }
		.aob { return 'aob' }
		.encrypted { return 'encrypted' }
		.auto { return 'auto' }
	}
}
