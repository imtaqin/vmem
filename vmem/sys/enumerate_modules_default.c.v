module sys

// enumerate_modules is an unsupported-platform fallback.
pub fn enumerate_modules(h voidptr, mut sink ModuleSink) ! {
	return error('enumerate_modules unsupported on this OS')
}
