module vmem

import vmem.sys

// The sys-layer prot bits are the wire ABI pushed into Region.prot;
// they must stay identical to the public constants (AGENTS.md §4).
fn test_prot_bits_match() {
	assert prot_read == sys.prot_read
	assert prot_write == sys.prot_write
	assert prot_exec == sys.prot_exec
	assert prot_cow == sys.prot_cow
}
