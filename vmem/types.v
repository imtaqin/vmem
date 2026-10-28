module vmem

// ValueKind is the scan/edit value width + encoding.
// Sizes: byte=1 word=2 dword=4 qword=8 float=4 double=8.
// aob/text widths come from their pattern bytes (see ScanPattern).
pub enum ValueKind {
	byte
	word
	dword
	qword
	float
	double
	text
	aob
	encrypted
	auto
}

// TextEncoding is the byte encoding of text scans/edits.
pub enum TextEncoding {
	ascii
	utf8
	utf16le
	utf16be
}

// CompareOp is a scan comparison. First-scan ops use value only;
// delta ops compare against the value saved at the previous scan.
pub enum CompareOp {
	eq
	ne
	gt
	ge
	lt
	le
	between
	changed
	unchanged
	increased
	increased_by
	decreased
	decreased_by
	same_as_first
	unknown
	fuzzy_eq
	fuzzy_ne
	fuzzy_gt
	fuzzy_lt
}

// RegionClass mirrors the GameGuardian region classes; derived per OS
// from raw region facts by classify_region.
pub enum RegionClass {
	code_app
	code_sys
	java_heap
	c_heap
	c_alloc
	c_bss
	c_data
	stack
	anonymous
	ashmem
	video
	other
	bad
}

// Region protection bits; combined in Region.prot.
pub const prot_read = u32(1)
pub const prot_write = u32(2)
pub const prot_exec = u32(4)
pub const prot_cow = u32(8)

// Region is one contiguous mapped range of a target process.
pub struct Region {
pub:
	base  u64
	size  u64
	prot  u32
	class RegionClass
	name  string
}

// ModuleInfo is a loaded image (exe/dll/so) in the target.
pub struct ModuleInfo {
pub:
	base u64
	size u64
	path string
	name string
}

// ProcessInfo is an enumerated OS process.
pub struct ProcessInfo {
pub:
	pid  int
	name string
	path string
}

// ResultEntry is one scan hit with its current and previous decoded value.
// raw holds the current bytes (LE for scalars). stable counts consecutive
// rescans the entry survived.
pub struct ResultEntry {
pub mut:
	address u64
	kind    ValueKind
	value   f64
	prev    f64
	raw     []u8
	stable  int
}

// Capabilities advertises optional backend features (ARCHITECTURE.md §3).
pub struct Capabilities {
pub:
	scan_offload bool
	regs         bool
	alloc        bool
	inject       bool
}

// FreezeMode is the rewrite policy of a frozen entry (GG FREEZE_* model).
pub enum FreezeMode {
	normal
	may_increase
	may_decrease
	in_range
}

// FreezeEntry is one address kept at a value by the freeze ticker.
// interval is the rewrite period in ms (0 = list default).
pub struct FreezeEntry {
pub mut:
	addr     u64
	kind     ValueKind
	value    f64
	from     f64
	to       f64
	mode     FreezeMode
	interval int
	writes   int
}

// PointerPath is a pointer chain: base address (or module + offset base)
// followed by one offset per dereference (see pointer_resolve).
pub struct PointerPath {
pub:
	module  string
	base    u64
	offsets []i64
}

// HookArch selects the trampoline jump encoding for the target ISA.
pub enum HookArch {
	x64
	arm64
}

// Hook records an installed detour (see install_hook/remove_hook).
pub struct Hook {
pub:
	addr            u64
	hook_addr       u64
	trampoline_addr u64
	arch            HookArch
	stolen          []u8
	jmp_len         int
}

// TableEntry is one saved-list row (see save_list/load_list).
pub struct TableEntry {
pub:
	address u64
	kind    ValueKind
	value   f64
	name    string
}

// ScanFilter restricts a first scan to part of the target VA space.
// classes is a RegionClass bitmask (see class_bit); 0 = every class.
pub struct ScanFilter {
pub:
	start        u64
	end          u64
	classes      u64
	prot_require u32
	prot_reject  u32
}

// ScanPlan describes one scan pass (first/next/refine).
// value/value2 carry the operand(s); between uses both.
// align is the fast-scan stride (0 or 1 = every address).
//
// Pattern scans (kind .aob/.text): pattern carries the bytes and a mask
// (0xFF = must match, 0x00 = wildcard); text scans set text+enc and are
// encoded into the pattern at plan build time (see pattern_from_text).
// mask (address mask) applies to eq/ne on scalar kinds: (cur^value)&mask==0.
// xor_key de-encodes scalar values before comparison (cur^xor_key).
// fuzzy_* ops treat value as the delta: fuzzy_eq |cur-prev|<=delta,
// fuzzy_ne |cur-prev|>delta, fuzzy_gt cur>prev+delta, fuzzy_lt cur<prev-delta.
pub struct ScanPlan {
pub:
	kind    ValueKind
	op      CompareOp
	value   f64
	value2  f64
	align   u64 = 1
	limit   int
	filter  ScanFilter
	pattern ScanPattern
	mask    u64
	xor_key u64
}

// ScanPattern is a byte pattern with a per-byte mask (0xFF exact, 0x00 any).
// ranges holds optional value-range cells (group scans with a~b cells):
// after the mask matches, each cell's decoded value must fall in [lo, hi].
pub struct ScanPattern {
pub:
	bytes  []u8
	mask   []u8
	ranges []CellRange
}

// ScanHits is the transport-level hit list (addresses + packed raw bytes).
pub struct ScanHits {
pub mut:
	stride    int
	addresses []u64
	raw       []u8
	stable    []u32
}

// CellRange is one range cell of a group pattern.
pub struct CellRange {
pub:
	off      int
	lo       f64
	hi       f64
	is_float bool
	width    int
}

// ScanSession accumulates scan hits across passes. Backend handles are not
// stored: every engine call takes `mut backend MemoryBackend` (see
// ARCHITECTURE.md §4). prev_raw/first_raw are packed per-hit bytes with
// stride kind_size.
pub struct ScanSession {
mut:
	kind       ValueKind
	op         CompareOp
	align      u64 = 1
	stride     int
	pattern    ScanPattern
	addresses  []u64
	prev_raw   []u8
	first_raw  []u8
	stable     []u32
	total_hits int
pub mut:
	scans int
}
