module sys

// Protection bits pushed by RegionSink. Values are the vmem ABI and MUST
// match vmem/types.v (enforced by prot_bits_match_test.v).
pub const prot_read = u32(1)
pub const prot_write = u32(2)
pub const prot_exec = u32(4)
pub const prot_cow = u32(8)

// Region kind codes pushed by RegionSink.
pub const kind_image = u32(0)
pub const kind_mapped = u32(1)
pub const kind_private = u32(2)
pub const kind_other = u32(3)
