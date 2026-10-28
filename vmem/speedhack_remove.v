module vmem

// speedhack_remove restores the original GetTickCount (byte-exact via the
// hook revert) and frees the cave page.
pub fn speedhack_remove(mut b LocalBackend, s Speedhack) ! {
	remove_hook(mut b, s.hook) or { return wrap_err(.access_denied, 'speedhack_remove hook', err) }
	b.free_memory(s.page) or {}
}
