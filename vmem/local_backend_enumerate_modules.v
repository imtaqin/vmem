module vmem

import vmem.sys

// enumerate_modules returns the loaded images of the target.
pub fn (mut b LocalBackend) enumerate_modules() ![]ModuleInfo {
	if !b.attached {
		return new_error(.not_attached, 'enumerate_modules', 0)
	}
	mut c := ModuleCollector{}
	sys.enumerate_modules(b.handle, mut c) or {
		return wrap_err(.access_denied, 'enumerate_modules', err)
	}
	return c.out
}
