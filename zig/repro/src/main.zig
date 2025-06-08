const std = @import("std");

test "repro" {
    const foo = @embedFile("foo.txt");
    std.testing.allocator.free(foo);
}
