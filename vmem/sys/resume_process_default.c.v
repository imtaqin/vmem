module sys

// resume_process is an unsupported-platform fallback.
pub fn resume_process(h voidptr) ! {
	return error('resume_process unsupported on this OS')
}
