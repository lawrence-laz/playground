const std = @import("std");

pub fn main() !void {
    const foo: []const u8 = &.{ 'a', 'b', 'c' };
    const bar: []const u8 = &.{ 'd', 'e', 'f' };
    inline for (&.{ foo, bar }) |slice| {
        for (slice) |item| {
            std.log.debug("{c}", .{item});
        }
    }
}
