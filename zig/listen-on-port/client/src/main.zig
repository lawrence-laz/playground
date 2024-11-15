const std = @import("std");
const net = std.net;
const time = std.time;

fn connect(address: net.Address) void {
    const socket = net.tcpConnectToAddress(address) catch @panic("oops");
    defer socket.close();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var pool: std.Thread.Pool = undefined;
    try std.Thread.Pool.init(&pool, .{ .allocator = allocator });
    const localhost = try net.Address.parseIp("127.0.0.1", 19002);
    const expected_connections_count = 3000;
    var actual_connections_count: usize = 0;
    const first_timestamp = time.milliTimestamp();
    while (actual_connections_count < expected_connections_count) : (actual_connections_count += 1) {
        try pool.spawn(connect, .{localhost});
    }
    pool.deinit();
    const last_timestamp = time.milliTimestamp();
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("Client finished in {d} ms\n", .{last_timestamp - first_timestamp});
    try bw.flush();
}
