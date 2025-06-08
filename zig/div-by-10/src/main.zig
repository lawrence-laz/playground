const std = @import("std");

export fn foo(number: u32) usize {
    var i: usize = 0;
    while (i < 1000000) : (i += 1) {
        var local: u32 = number;
        while (local > 10) {
            std.log.err("div", .{});
            local /= 10;
            i += 1;
        }
    }
    return i;
}

pub fn main() !void {
    const timestamp: i64 = std.time.milliTimestamp();
    const a = foo(std.math.maxInt(u32));
    std.log.err("dur:{d}", .{std.time.milliTimestamp() - timestamp});
    std.log.err("res:{d}", .{a});
}
