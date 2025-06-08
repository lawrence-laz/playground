const std = @import("std");

test "std.sort" {
    var foo = [_]u8{ 'b', 'c', 'a', 'e', 'f', 'd' };
    std.mem.sort(u8, &foo, {}, struct {
        fn f(_: void, a: u8, b: u8) bool {
            return a < b;
        }
    }.f);
    try std.testing.expectEqualStrings("abcdef", &foo);
}

test "sort arraylist" {
    var left = std.ArrayList(u32).init(std.testing.allocator);
    defer left.deinit();

    try left.append(2);
    try left.append(3);
    try left.append(1);

    std.mem.sort(u32, left.items, {}, std.sort.asc(u32));

    try std.testing.expectEqualSlices(u32, &.{ 1, 2, 3 }, left.items);
}
