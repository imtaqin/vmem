module sys

// close_process releases nothing: Linux handles are pseudo-handles.
pub fn close_process(h voidptr) {}
