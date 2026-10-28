module sys

// enumerate_processes is an unsupported-platform fallback.
pub fn enumerate_processes(mut sink ProcessSink) ! {
	return error('enumerate_processes unsupported on this OS')
}
