const std = @import("std");

fn foo() ?usize {
    return 123;
}

test "switch on optional" {
    switch (foo() orelse return) {
        123 => return,
        else => try std.testing.expect(false),
    }
}
