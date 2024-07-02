const std = @import("std");

pub fn encodeBuf(input: []const u5, buffer: []u8) !void {
    const encode_map = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
    for (input, 0..) |value, i| {
        if (i >= buffer.len) {
            return error.BufferOverflow;
        }

        buffer[i] = encode_map[value];
    }
}

test encodeBuf {
    var buffer: [2]u8 = undefined;
    try encodeBuf(&[_]u5{ 10, 1 }, &buffer);
    try std.testing.expectEqualSlices(u8, "A1", &buffer);
    try encodeBuf(&[_]u5{ 28, 25 }, &buffer);
    try std.testing.expectEqualSlices(u8, "WS", &buffer);
}

pub fn decodeBuf(input: []const u8, buffer: []u5) !void {
    for (input, 0..) |symbol, i| {
        if (symbol == '-') {
            continue;
        }

        if (i >= buffer.len) {
            return error.BufferOverflow;
        }

        const maybe_decoded: ?u5 = switch (symbol) {
            '0', 'O', 'o' => 0,
            '1', 'I', 'i', 'L', 'l' => 1,
            '2' => 2,
            '3' => 3,
            '4' => 4,
            '5' => 5,
            '6' => 6,
            '7' => 7,
            '8' => 8,
            '9' => 9,
            'A', 'a' => 10,
            'B', 'b' => 11,
            'C', 'c' => 12,
            'D', 'd' => 13,
            'E', 'e' => 14,
            'F', 'f' => 15,
            'G', 'g' => 16,
            'H', 'h' => 17,
            'J', 'j' => 18,
            'K', 'k' => 19,
            'M', 'm' => 20,
            'N', 'n' => 21,
            'P', 'p' => 22,
            'Q', 'q' => 23,
            'R', 'r' => 24,
            'S', 's' => 25,
            'T', 't' => 26,
            'V', 'v' => 27,
            'W', 'w' => 28,
            'X', 'x' => 29,
            'Y', 'y' => 30,
            'Z', 'z' => 31,
            else => null,
        };

        if (maybe_decoded) |decoded| {
            buffer[i] = decoded;
        } else {
            return error.InvalidBase32Symbol;
        }
    }
}

test decodeBuf {
    var buffer: [2]u5 = undefined;
    try decodeBuf("aL", &buffer);
    try std.testing.expectEqualSlices(u5, &[_]u5{ 10, 1 }, &buffer);
    try decodeBuf("WS", &buffer);
    try std.testing.expectEqualSlices(u5, &[_]u5{ 28, 25 }, &buffer);
}
