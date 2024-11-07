const std = @import("std");
const base32 = @import("base32.zig");

pub const Ulid = packed struct {
    random: u80,
    timestamp: u48,

    pub fn new() Ulid {
        return .{
            .timestamp = std.math.cast(u48, std.time.milliTimestamp()) orelse @panic("if you see this I am long dead"),
            .random = std.crypto.random.int(u80),
        };
    }

    pub fn parse(string: []const u8) Ulid {
        var buffer: [26]u5 = undefined;
        base32.decodeBuf(string, &buffer) catch @panic("bad ulid");
        return .{
            .timestamp = std.math.cast(u48, sliceToInt(u50, u5, buffer[0..10])) orelse @panic("bad ulid"),
            .random = sliceToInt(u80, u5, buffer[10..26]),
        };
    }

    pub fn format(self: Ulid, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        const text = self.toString();
        try writer.print("{s}", .{text});
    }

    pub fn jsonStringify(self: Ulid, json_writer: anytype) !void {
        try json_writer.write(self.toString());
    }

    pub fn toString(self: Ulid) [26]u8 {
        const input: [26]u5 = intToArray(u128, u5, @bitCast(self));
        var buf: [26]u8 = undefined;
        base32.encodeBuf(&input, &buf) catch unreachable;
        return buf;
    }

    pub fn min(a: Ulid, b: Ulid) Ulid {
        if (a.timestamp < b.timestamp) {
            return a;
        } else if (a.timestamp > b.timestamp) {
            return b;
        } else if (a.random < b.random) {
            return a;
        } else {
            return b;
        }
    }

    pub fn equals(a: Ulid, b: Ulid) bool {
        return a.timestamp == b.timestamp and a.random == b.random;
    }

    fn intToArray(
        comptime TInt: type,
        comptime TItem: type,
        input: TInt,
    ) [(@typeInfo(TInt).Int.bits + @typeInfo(TItem).Int.bits - 1) / @typeInfo(TItem).Int.bits]TItem {
        var result: [(@typeInfo(TInt).Int.bits + @typeInfo(TItem).Int.bits - 1) / @typeInfo(TItem).Int.bits]TItem = undefined;
        var i: usize = 0;
        while (i < result.len) : (i += 1) {
            result[i] = 0;
        }

        var number = input;
        const item_bits = @typeInfo(TItem).Int.bits;
        const step = std.math.pow(TInt, 2, @intCast(item_bits));
        while (true) {
            result[i - 1] = @intCast(number % step);
            number = number / step;
            i -= 1;
            if (number == 0) {
                break;
            }
        }

        return result;
    }

    fn sliceToInt(
        comptime TInt: type,
        comptime TSliceItem: type,
        slice: []const TSliceItem,
    ) TInt {
        const int_bit_count = @typeInfo(TInt).Int.bits;
        const slice_item_bit_count = @typeInfo(TSliceItem).Int.bits;
        if (int_bit_count < slice_item_bit_count * slice.len) {
            @panic("overflow");
        }
        var result: TInt = 0;
        for (slice, 0..) |item, i| {
            const shift: std.math.Log2Int(TInt) = @intCast(slice_item_bit_count * (slice.len - 1 - i));
            result = result | (@as(TInt, item) << shift);
        }
        return result;
    }
};

test "intToArray" {
    const input: u128 = 0x0055527c075f8e99a82301f384f494d8;
    const expected: [26]u5 = .{ 0b00000, 0b00000, 0b01010, 0b10101, 0b01001, 0b00111, 0b11000, 0b00001, 0b11010, 0b11111, 0b10001, 0b11010, 0b01100, 0b11010, 0b10000, 0b01000, 0b11000, 0b00001, 0b11110, 0b01110, 0b00010, 0b01111, 0b01001, 0b00101, 0b00110, 0b11000 };
    const actual = Ulid.intToArray(u128, u5, input);
    try std.testing.expectEqualSlices(u5, &expected, &actual);
}

test "toString" {
    const expected_string = "01AN4Z07BY79KA1307SR9X4MV3";
    const ulid = Ulid.parse(expected_string);
    const actual_string: [26]u8 = ulid.toString();
    try std.testing.expectEqualSlices(u8, expected_string, &actual_string);
}

test "parse" {
    {
        const string = "7ZZZZZZZZZZZZZZZZZZZZZZZZZ";
        const ulid = Ulid.parse(string);
        try std.testing.expectEqual(@as(u48, 0b111111111111111111111111111111111111111111111111), ulid.timestamp);
        try std.testing.expectEqual(@as(u80, 0b11111111111111111111111111111111111111111111111111111111111111111111111111111111), ulid.random);
        try std.testing.expectEqual(
            @as(u128, 0b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111),
            @as(u128, @bitCast(ulid)),
        );
    }
    {
        const string = "7ZZZZZZZZZ0000000000000001";
        const ulid = Ulid.parse(string);
        try std.testing.expectEqual(@as(u48, 0b111111111111111111111111111111111111111111111111), ulid.timestamp);
        try std.testing.expectEqual(@as(u80, 0b00000000000000000000000000000000000000000000000000000000000000000000000000000001), ulid.random);
        try std.testing.expectEqual(
            @as(u128, 0b11111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000001),
            @as(u128, @bitCast(ulid)),
        );
    }
    {
        const string = "01J21MXMKHR8K366H6VXZ7HSQG";
        const ulid = Ulid.parse(string);
        try std.testing.expectEqual(@as(u48, 0b000000011001000010000011010011101101001001110001), ulid.timestamp);
        try std.testing.expectEqual(@as(u80, 0b11000010001001100011001100011010001001101101111101111110011110001110011011110000), ulid.random);
        try std.testing.expectEqual(
            @as(u128, 0b00000001100100001000001101001110110100100111000111000010001001100011001100011010001001101101111101111110011110001110011011110000),
            @as(u128, @bitCast(ulid)),
        );
    }
}

test "use in hashmap" {
    const ulid1 = Ulid.new();
    const ulid2 = Ulid.new();
    var hashmap = std.AutoHashMap(Ulid, []const u8).init(std.testing.allocator);
    defer hashmap.deinit();
    try hashmap.put(ulid1, "first");
    try hashmap.put(ulid2, "second");
    try std.testing.expectEqualSlices(u8, "first", hashmap.get(ulid1).?);
    try std.testing.expectEqualSlices(u8, "second", hashmap.get(ulid2).?);
}
