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
