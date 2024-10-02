const std = @import("std");

test "simple test" {
    var arena_allocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_allocator.deinit();

    var list = std.ArrayListUnmanaged(i32){};
    try list.append(arena_allocator.allocator(), 123);
}
