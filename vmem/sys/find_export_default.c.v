module sys

// find_export is an unsupported-platform fallback.
pub fn find_export(module_name string, fn_name string) !u64 {
	return error('find_export unsupported on this OS')
}
