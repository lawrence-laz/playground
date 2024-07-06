const std = @import("std");
const builtin = @import("builtin");

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

test "u32 -> [4]u8" {
    const input: u32 = 0x12345678;
    const actual: [4]u8 = intToArray(u32, u8, input);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x12, 0x34, 0x56, 0x78 }, &actual);
}

test "u32 -> [8]u4" {
    const input: u32 = 0x12345678;
    const actual: [8]u4 = intToArray(u32, u4, input);
    try std.testing.expectEqualSlices(u4, &[_]u4{ 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8 }, &actual);
}
