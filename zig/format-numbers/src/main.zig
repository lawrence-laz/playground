const std = @import("std");

test "format nanoseconds into 0:0.000" {
    const duration_in_ns: u64 = 1_001_000_000;
    const duration = try std.fmt.allocPrint(
        std.testing.allocator,
        "{d}:{d}.{d:0>3}",
        .{
            duration_in_ns / std.time.ns_per_min,
            duration_in_ns % std.time.ns_per_min / std.time.ns_per_s,
            duration_in_ns % std.time.ns_per_s / std.time.ns_per_ms,
        },
    );
    defer std.testing.allocator.free(duration);
    try std.testing.expectEqualStrings("0:1.001", duration);
}

test "format nanoseconds using std.fmt" {
    const duration_in_ns: u64 = 1_001_000_000;
    const duration = try std.fmt.allocPrint(
        std.testing.allocator,
        "{}",
        .{std.fmt.fmtDuration(duration_in_ns)},
    );
    defer std.testing.allocator.free(duration);
    try std.testing.expectEqualStrings("1.001s", duration);
}

test "format numbers as table" {
    const input = [_]f32{
        0.01234,
        0.1,
        -0.123,
        104.567,
    };
    const expected = [_][]const u8{
        "  0.0123",
        "  0.1000",
        " -0.1230",
        "104.5670",
    };
    for (input, 0..) |number, i| {
        const actual = try std.fmt.allocPrint(
            std.testing.allocator,
            "{d: >8.4}",
            .{number},
        );
        defer std.testing.allocator.free(actual);
        try std.testing.expectEqualStrings(expected[i], actual);
    }
}
