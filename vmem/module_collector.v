module vmem

// ModuleCollector implements vmem/sys ModuleSink into domain ModuleInfo.
struct ModuleCollector {
mut:
	out []ModuleInfo
}

fn (mut c ModuleCollector) push(base u64, size u64, path string) {
	mut name := path
	mut cut := -1
	if i := path.last_index('/') {
		cut = i
	}
	if i := path.last_index('\\') {
		if i > cut {
			cut = i
		}
	}
	if cut >= 0 {
		name = path[cut + 1..]
	}
	c.out << ModuleInfo{
		base: base
		size: size
		path: path
		name: name
	}
}
