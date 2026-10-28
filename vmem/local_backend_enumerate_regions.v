module vmem

import vmem.sys

// enumerate_regions returns the committed memory regions of the target.
pub fn (mut b LocalBackend) enumerate_regions() ![]Region {
	if !b.attached {
		return new_error(.not_attached, 'enumerate_regions', 0)
	}
	mut c := RegionCollector{}
	sys.enumerate_regions(b.handle, mut c) or {
		return wrap_err(.access_denied, 'enumerate_regions', err)
	}
	return c.out
}
