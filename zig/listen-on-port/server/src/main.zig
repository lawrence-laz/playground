const std = @import("std");
const net = std.net;
const time = std.time;

pub fn handle_connection(connection: net.Server.Connection) void {
    defer connection.stream.close();
}

pub fn main() !void {
    const localhost = try net.Address.parseIp("127.0.0.1", 19002);
    var server = try localhost.listen(.{});
    defer server.deinit();
    const expected_client_count = 3000;
    var actual_client_count: usize = 0;

    while (actual_client_count < expected_client_count) : (actual_client_count += 1) {
        const connection = try server.accept();
        const thread = try std.Thread.spawn(.{}, handle_connection, .{connection});
        thread.detach();
        // defer connection.stream.close();
    }
}
