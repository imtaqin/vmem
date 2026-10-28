module vmem

// class_bit returns the ScanFilter.classes bitmask bit for a RegionClass.
pub fn class_bit(c RegionClass) u64 {
	return u64(1) << u64(int(c))
}
