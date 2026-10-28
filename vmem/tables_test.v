module vmem

import os

// Saved-list and CT import tests (golden + roundtrip).

fn test_save_load_roundtrip() {
	path := os.join_path(os.temp_dir(), 'vmem_table_test.txt')
	entries := [
		TableEntry{
			address: u64(0x12345678)
			kind:    .dword
			value:   75
			name:    'health'
		},
		TableEntry{
			address: u64(0x7FFF0000)
			kind:    .float
			value:   1.5
			name:    'speed'
		},
	]
	n := save_list(path, entries) or { panic(err) }
	assert n == 2
	back := load_list(path) or { panic(err) }
	assert back.len == 2
	assert back[0].address == u64(0x12345678)
	assert back[0].kind == .dword
	assert back[0].value == 75
	assert back[0].name == 'health'
	assert back[1].kind == .float
	assert back[1].value == 1.5
	os.rm(path) or {}
}

fn test_load_list_gg_rows() {
	path := os.join_path(os.temp_dir(), 'vmem_table_gg.txt')
	os.write_file(path, '# comment\n0x1A2B 42 dword\n\n0x2C3D -3 qword\n') or { panic(err) }
	back := load_list(path) or { panic(err) }
	assert back.len == 2
	assert back[0].address == u64(0x1A2B)
	assert back[0].value == 42
	assert back[0].kind == .dword
	assert back[1].value == -3
	assert back[1].kind == .qword
	os.rm(path) or {}
}

fn test_import_ct_subset() {
	path := os.join_path(os.temp_dir(), 'vmem_table_test.ct')
	ct := '<?xml version="1.0" encoding="utf-8"?>
<CheatTable>
  <CheatEntries>
    <CheatEntry>
      <Description>health</Description>
      <Address>1A2B3C</Address>
      <VariableType>4 Bytes</VariableType>
    </CheatEntry>
    <CheatEntry>
      <Description>speed</Description>
      <Address>game.exe+1F48</Address>
      <VariableType>Float</VariableType>
    </CheatEntry>
  </CheatEntries>
</CheatTable>'
	os.write_file(path, ct) or { panic(err) }
	entries := import_ct(path) or { panic(err) }
	assert entries.len == 2
	assert entries[0].address == u64(0x1A2B3C)
	assert entries[0].name == 'health'
	assert entries[0].kind == .dword
	assert entries[1].address == 0
	assert entries[1].name == 'game.exe+1F48'
	assert entries[1].kind == .float
	os.rm(path) or {}
}
