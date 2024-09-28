const std = @import("std");

test "array of data structures" {
    const Foo = struct { foo: bool };
    // What's the appropriate way to initialize a comptime-sized array of unmanaged data structures?
    var array: [3]std.AutoHashMapUnmanaged(usize, Foo) = .{.{}} ** 3;
    defer {
        for (&array) |*item| {
            item.deinit(std.testing.allocator);
        }
    }

    try array[0].put(std.testing.allocator, 123, .{ .foo = true });

    try std.testing.expectEqual(true, array[0].get(123).?.foo);
    try std.testing.expectEqual(0, array[1].count());
}
