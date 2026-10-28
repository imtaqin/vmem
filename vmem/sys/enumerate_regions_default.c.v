module sys

// enumerate_regions is an unsupported-platform fallback.
pub fn enumerate_regions(h voidptr, mut sink RegionSink) ! {
	return error('enumerate_regions unsupported on this OS')
}
