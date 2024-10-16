const std = @import("std");

fn PackRT(T: type, len: comptime_int) type {
    return std.meta.Int(.unsigned, @bitSizeOf(T) * len);
}

// From discord by @Cloudef
fn pack(T: type, arr: anytype) PackRT(T, std.meta.fields(@TypeOf(arr)).len) {
    var ret: PackRT(T, std.meta.fields(@TypeOf(arr)).len) = 0;
    inline for (std.meta.fields(@TypeOf(arr))) |field| {
        ret <<= @bitSizeOf(T);
        if (field.type == bool) {
            ret |= @intFromBool(@field(arr, field.name));
        } else {
            ret |= @truncate(@field(arr, field.name));
        }
    }
    return ret;
}

pub fn main() void {
    for (1..100 + 1) |i| {
        switch (pack(u1, .{ i % 3 == 0, i % 5 == 0 })) {
            pack(u1, .{ 1, 1 }) => std.log.info("FizzBuzz", .{}),
            pack(u1, .{ 1, 0 }) => std.log.info("Fizz", .{}),
            pack(u1, .{ 0, 1 }) => std.log.info("Buzz", .{}),
            else => std.log.info("{}", .{i}),
        }
    }
}
