module main

import os

// vmem-cli — terminal front end for the vmem library.
//
//   vmem ps [--json]                        list processes
//   vmem maps <pid> [--json]                memory regions
//   vmem mods <pid> [--json]                loaded modules
//   vmem read <pid> <addr> <type> [--json]  typed read
//   vmem write <pid> <addr> <type> <value>  typed write
//   vmem scan ...                           scan sessions (see cmd_scan.v)
//   vmem results --state <file>             show session results
//   vmem freeze ...                         freeze list (see cmd_freeze.v)
//   vmem ptr <pid> <target> ...             pointer scan
//   vmem dump <pid> <start> <end> <file>    memory dump (--hex for text)
//
// Addresses accept decimal or 0x hex. Types: byte word dword qword float
// double text. See docs/FEATURE-PARITY.md for the covered surface.
fn main() {
	args := os.args[1..]
	if args.len == 0 {
		print_usage()
		exit(1)
	}
	cmd := args[0]
	rest := args[1..]
	code := match cmd {
		'ps' {
			cmd_ps(rest)
		}
		'maps' {
			cmd_maps(rest)
		}
		'mods' {
			cmd_mods(rest)
		}
		'read' {
			cmd_read(rest)
		}
		'write' {
			cmd_write(rest)
		}
		'scan' {
			cmd_scan(rest)
		}
		'results' {
			cmd_results(rest)
		}
		'freeze' {
			cmd_freeze(rest)
		}
		'ptr' {
			cmd_ptr(rest)
		}
		'dump' {
			cmd_dump(rest)
		}
		else {
			print_usage()
			1
		}
	}

	exit(code)
}

fn print_usage() {
	eprintln('vmem-cli — process memory tool (authorized targets only)')
	eprintln('usage: vmem ps|maps|mods|read|write|scan|results|freeze|ptr|dump ...')
	eprintln('see cli/main.v header for the command summary')
}
