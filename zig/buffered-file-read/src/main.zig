const std = @import("std");

pub fn main() !void {
    var threaded: std.Io.Threaded = .init_single_threaded;
    const io = threaded.io();
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buf_reader: [5]u8 = undefined;
    var reader = file.reader(io, &buf_reader);

    var buf: [5]u8 = undefined;
    while (true) {
        const size = try reader.interface.readSliceShort(&buf);
        if (size == 0) {
            break;
        }
        std.debug.print("|{s}", .{buf[0..size]});
    }
    std.log.debug("Done reading!", .{});
}
