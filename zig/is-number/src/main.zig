const std = @import("std");

fn isNumber(text: []const u8) bool {
    const State = enum(u3) {
        init,
        zero,
        hex_prefix,
        bin_prefix,
        dec,
        hex,
        bin,
        const Self = @This();
        fn pack(self: Self, c: u8) u11 {
            const combined: packed struct(u11) { c: u8, s: Self } = .{ .c = c, .s = self };
            return @bitCast(combined);
        }
    };
    var state: State = .init;
    // TODO: Try rewrite this in 0.14 zig with labeled switch prongs
    for (text, 0..) |c, index| {
        if (index == 0 and (c == '+' or c == '-')) continue;
        state = switch (state.pack(c)) {
            State.init.pack('0') => .zero,
            State.init.pack('1')...State.init.pack('9') => .dec,
            State.zero.pack('0')...State.zero.pack('0') => .dec,
            State.zero.pack('x') => .hex_prefix,
            State.zero.pack('b') => .bin_prefix,
            State.hex_prefix.pack('0')...State.hex_prefix.pack('9'),
            State.hex_prefix.pack('A')...State.hex_prefix.pack('F'),
            State.hex_prefix.pack('a')...State.hex_prefix.pack('f'),
            State.hex.pack('0')...State.hex.pack('9'),
            State.hex.pack('A')...State.hex.pack('F'),
            State.hex.pack('a')...State.hex.pack('f'),
            => .hex,
            State.bin_prefix.pack('0'),
            State.bin_prefix.pack('1'),
            State.bin.pack('0'),
            State.bin.pack('1'),
            => .bin,
            State.dec.pack('0')...State.dec.pack('9') => .dec,
            else => return false,
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
