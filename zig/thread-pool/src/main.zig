const std = @import("std");

const Foo = struct {
    pub fn fooBar(self: Foo, i: usize) void {
        _ = self;
        std.debug.print("{d}|", .{i});
    }
};

test "simple test" {
    var thread_pool: std.Thread.Pool = undefined;
    try std.Thread.Pool.init(&thread_pool, .{ .allocator = std.testing.allocator });
    const foo: Foo = .{};
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        // try thread_pool.spawn(std.debug.print, .{ "{d}|", .{i} });
        try thread_pool.spawn(@TypeOf(foo).fooBar, .{ foo, i });
    }
    defer thread_pool.deinit();
}
