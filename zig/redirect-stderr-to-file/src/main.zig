const std = @import("std");

pub fn main() !void {
    {
        const file1 = try std.fs.cwd().createFile("first", .{});
        try std.posix.dup2(file1.handle, std.posix.STDERR_FILENO);
        file1.close();
        std.debug.print("This should go to first file", .{});
    }
    {
        const file2 = try std.fs.cwd().createFile("second", .{});
        try std.posix.dup2(file2.handle, std.posix.STDERR_FILENO);
        file2.close();
        std.debug.print("This should go to second file", .{});
    }
}
