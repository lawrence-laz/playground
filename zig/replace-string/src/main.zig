const std = @import("std");

test "replace all instances" {
    const input = "Hello ___FOO___, my name is ___BAR___! How are you doing, ___FOO___?";
    const actual1 = try std.mem.replaceOwned(u8, std.testing.allocator, input, "___FOO___", "Foo");
    defer std.testing.allocator.free(actual1);
    const actual2 = try std.mem.replaceOwned(u8, std.testing.allocator, actual1, "___BAR___", "Bar");
    defer std.testing.allocator.free(actual2);
    try std.testing.expectEqualStrings("Hello Foo, my name is Bar! How are you doing, Foo?", actual2);
}
