module sys

// enumerate_threads is an unsupported-platform fallback.
pub fn enumerate_threads(h voidptr) ![]int {
	return error('enumerate_threads unsupported on this OS')
}
