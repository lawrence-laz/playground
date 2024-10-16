const std = @import("std");

fn isNumber(text: []const u8) bool {
    const State = enum { init, zero, hex_prefix, bin_prefix, dec, hex, bin };
    var state: State = .init;
    for (text, 0..) |c, index| {
        if (index == 0 and (c == '-' or c == '+')) continue;
        state = switch (state) {
            .init => switch (c) {
                '0' => .zero,
                '1'...'9' => .dec,
                else => return false,
            },
            .zero => switch (c) {
                '0'...'9' => .dec,
                'x' => .hex_prefix,
                'b' => .bin_prefix,
                else => return false,
            },
            .hex_prefix, .hex => switch (c) {
                '0'...'9', 'A'...'F', 'a'...'f' => .hex,
                else => return false,
            },
            .bin_prefix, .bin => switch (c) {
                '0', '1' => .bin,
                else => return false,
            },
            .dec => switch (c) {
                '0'...'9' => .dec,
                else => return false,
            },
        };
    }
    return switch (state) {
        .zero, .dec, .hex, .bin => true,
        else => false,
    };
}

test isNumber {
    // Decimal
    try std.testing.expectEqual(true, isNumber("0"));
    try std.testing.expectEqual(true, isNumber("000"));
    try std.testing.expectEqual(true, isNumber("123"));
    try std.testing.expectEqual(true, isNumber("-123"));
    try std.testing.expectEqual(true, isNumber("+123"));

    // TODO: Fractional
    // try std.testing.expectEqual(true, isNumber("123.456"));

    // Binary
    try std.testing.expectEqual(true, isNumber("0b0101"));

    // Hex
    try std.testing.expectEqual(true, isNumber("0xAAA"));
    try std.testing.expectEqual(true, isNumber("0xfff"));

    // Text
    try std.testing.expectEqual(false, isNumber("abc"));
    try std.testing.expectEqual(false, isNumber("0b012")); // Not binary
    try std.testing.expectEqual(false, isNumber("0x0XP")); // Not hex
}
