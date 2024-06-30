const std = @import("std");
const c = @cImport({
    @cInclude("unistd.h");
});

pub fn main() !void {
    const pid = c.getpid();
    std.log.debug("PID: {d}", .{pid});
}
