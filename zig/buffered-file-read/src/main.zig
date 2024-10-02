const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var reader = file.reader().any();

    var buffer: [5]u8 = undefined;
    while (true) {
        const size = try reader.read(&buffer);
        if (size == 0) {
            break;
        }
        std.debug.print("|{s}", .{buffer[0..size]});
    }
    std.log.debug("Done reading!", .{});
}
