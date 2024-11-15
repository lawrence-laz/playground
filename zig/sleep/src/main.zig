const std = @import("std");

pub fn main() !void {
    std.time.sleep(5 * std.time.ns_per_s);
    std.log.debug("5 seconds passed", .{});
}
