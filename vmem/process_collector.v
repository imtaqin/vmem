module vmem

// ProcessCollector implements vmem/sys ProcessSink into domain ProcessInfo.
struct ProcessCollector {
mut:
	out []ProcessInfo
}

fn (mut c ProcessCollector) push(pid int, name string, path string) {
	c.out << ProcessInfo{
		pid:  pid
		name: name
		path: path
	}
}
