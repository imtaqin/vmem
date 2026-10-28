module sys

// debug_attach is an unsupported-platform fallback.
pub fn debug_attach(pid int) ! {
	return error('debug_attach unsupported on this OS')
}
