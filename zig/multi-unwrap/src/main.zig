const std = @import("std");

pub fn main() !void {}

fn foo(
    p1: i32,
) void {
    _ = p1;
}

test "unwrap multiple values" {
    const maybe_a: ?i32 = null;
    const maybe_b: ?i32 = null;
    const maybe_c: ?i32 = null;
    const maybe_d: ?i32 = null;

    var result: ?i32 = null;

    // This can get out of hand
    if (maybe_a) |a| if (maybe_b) |b| if (maybe_c) |c| if (maybe_d) |d| {
        result = a + b + c + d;
    };

    // This is kind of nice, but can it be better?
    blk: {
        const a = maybe_a orelse break :blk;
        const b = maybe_b orelse break :blk;
        const c = maybe_c orelse break :blk;
        const d = maybe_d orelse break :blk;

        result = a + b + c + d;
    }
}
