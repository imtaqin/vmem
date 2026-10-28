module vmem

// Internal scan matchers (pure, allocation-free; AGENTS.md §4).
// Integer kinds compare as i64 (with plan.xor_key de-encoding applied and
// plan.mask masking eq/ne); float kinds as f64. Fuzzy ops treat plan.value
// as the delta. Pattern kinds match through match_pattern.

fn match_int(op CompareOp, cur i64, prev i64, first i64, v1 i64, v2 i64, delta i64) bool {
	match op {
		.eq {
			return cur == v1
		}
		.ne {
			return cur != v1
		}
		.gt {
			return cur > v1
		}
		.ge {
			return cur >= v1
		}
		.lt {
			return cur < v1
		}
		.le {
			return cur <= v1
		}
		.between {
			return cur >= v1 && cur <= v2
		}
		.changed {
			return cur != prev
		}
		.unchanged {
			return cur == prev
		}
		.increased {
			return cur > prev
		}
		.decreased {
			return cur < prev
		}
		.increased_by {
			return cur - prev == v1
		}
		.decreased_by {
			return prev - cur == v1
		}
		.same_as_first {
			return cur == first
		}
		.unknown {
			return true
		}
		.fuzzy_eq {
			d := cur - prev
			return d <= delta && d >= -delta
		}
		.fuzzy_ne {
			d := cur - prev
			return d > delta || d < -delta
		}
		.fuzzy_gt {
			return cur > prev + delta
		}
		.fuzzy_lt {
			return cur < prev - delta
		}
	}
}

fn match_float(op CompareOp, cur f64, prev f64, first f64, v1 f64, v2 f64, delta f64) bool {
	match op {
		.eq {
			return cur == v1
		}
		.ne {
			return cur != v1
		}
		.gt {
			return cur > v1
		}
		.ge {
			return cur >= v1
		}
		.lt {
			return cur < v1
		}
		.le {
			return cur <= v1
		}
		.between {
			return cur >= v1 && cur <= v2
		}
		.changed {
			return cur != prev
		}
		.unchanged {
			return cur == prev
		}
		.increased {
			return cur > prev
		}
		.decreased {
			return cur < prev
		}
		.increased_by {
			return cur - prev == v1
		}
		.decreased_by {
			return prev - cur == v1
		}
		.same_as_first {
			return cur == first
		}
		.unknown {
			return true
		}
		.fuzzy_eq {
			d := cur - prev
			return d <= delta && d >= -delta
		}
		.fuzzy_ne {
			d := cur - prev
			return d > delta || d < -delta
		}
		.fuzzy_gt {
			return cur > prev + delta
		}
		.fuzzy_lt {
			return cur < prev - delta
		}
	}
}

// match_pattern checks the byte mask and the optional range cells.
fn match_pattern(cur []u8, pat ScanPattern) bool {
	if cur.len < pat.bytes.len {
		return false
	}
	for i in 0 .. pat.bytes.len {
		if pat.mask[i] == 0 {
			continue
		}
		if cur[i] & pat.mask[i] != pat.bytes[i] & pat.mask[i] {
			return false
		}
	}
	for rc in pat.ranges {
		w := rc.width
		if w <= 0 || rc.off < 0 || rc.off + w > cur.len {
			continue
		}
		cell := cur[rc.off..rc.off + w]
		v := if rc.is_float {
			if w == 4 { f64(decode_f32_le(cell)) } else { decode_f64_le(cell) }
		} else {
			f64(decode_width_int(w, cell))
		}
		if v < rc.lo || v > rc.hi {
			return false
		}
	}
	return true
}

// match_kind dispatches on the value kind (int vs float vs pattern families).
fn match_kind(k ValueKind, op CompareOp, cur_b []u8, prev_b []u8, first_b []u8, plan ScanPlan) bool {
	match k {
		.aob, .text {
			match op {
				.eq { return match_pattern(cur_b, plan.pattern) }
				.ne { return !match_pattern(cur_b, plan.pattern) }
				.changed { return raw_differs(cur_b, prev_b) }
				.unchanged { return !raw_differs(cur_b, prev_b) }
				.unknown { return true }
				else { return false }
			}
		}
		.float, .double {
			return match_float(op, decode_kind_num(k, cur_b), decode_kind_num(k, prev_b), decode_kind_num(k,
				first_b), plan.value, plan.value2, plan.value)
		}
		else {
			cur := decode_kind_int(k, cur_b) ^ i64(plan.xor_key)
			prev := decode_kind_int(k, prev_b) ^ i64(plan.xor_key)
			first := decode_kind_int(k, first_b) ^ i64(plan.xor_key)
			v1 := i64(plan.value)
			if plan.mask != 0 && (op == .eq || op == .ne) {
				m := i64(plan.mask)
				hit := (cur ^ v1) & m == 0
				return if op == .eq { hit } else { !hit }
			}
			return match_int(op, cur, prev, first, v1, i64(plan.value2), i64(plan.value))
		}
	}
}

fn raw_differs(a []u8, b []u8) bool {
	if a.len != b.len {
		return true
	}
	for i in 0 .. a.len {
		if a[i] != b[i] {
			return true
		}
	}
	return false
}
