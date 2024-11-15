pub fn main() !void {
    std.debug.print("Run `zig build test` to run the tests.\n", .{});
}

const std = @import("std");

const ErrorMessage = struct {
    const_overriden: []const u8,
};

const Errors = struct {
    error_messages: ErrorMessage,
};

test "json" {
    const input =
        \\ {
        \\   "error_messages": {
        \\     "const_overriden": "something"
        \\   }
        \\ }
    ;
    const result = try std.json.parseFromSlice(Errors, std.testing.allocator, input, .{});
    defer result.deinit();
    try std.testing.expectEqualStrings("something", result.value.error_messages.const_overriden);
}

test "parse json" {
    const T = struct {
        foo: []const u8,
        bar: u8,
    };
    const input =
        \\ {
        \\   "foo": "FOO",
        \\   "bar": 123
        \\ }
    ;

    var result = try std.json.parseFromSlice(T, std.testing.allocator, input, .{});
    defer result.deinit();

    try std.testing.expectEqualSlices(u8, "FOO", result.value.foo);
    try std.testing.expectEqual(@as(u8, 123), result.value.bar);
}

test "stringify json" {
    const T = struct {
        foo: []const u8,
        bar: u8,
    };
    const input: T = .{
        .foo = "FOO",
        .bar = 123,
    };

    const result = try std.json.stringifyAlloc(std.testing.allocator, input, .{});

    defer std.testing.allocator.free(result);

    try std.testing.expectEqualSlices(u8, "{\"foo\":\"FOO\",\"bar\":123}", result);
}

const Tags = enum {
    foo,
    bar,
};

const TaggedUnion = union(Tags) {
    foo: struct {
        foo_field: u8,
        other_foo_field: []const u8,
        bool_foo_field: bool,
    },
    bar: struct {
        other_bar_field: []const u8,
        bool_bar_field: bool,
    },
};

test "stringify tagged union" {
    const input = TaggedUnion{
        .foo = .{
            .foo_field = 'L',
            .other_foo_field = "Hello from foo!",
            .bool_foo_field = false,
        },
    };

    const result = try std.json.stringifyAlloc(std.testing.allocator, input, .{});
    defer std.testing.allocator.free(result);

    const expected =
        \\{"foo":{"foo_field":76,"other_foo_field":"Hello from foo!","bool_foo_field":false}}
    ;
    try std.testing.expectEqualSlices(u8, expected, result);
}

test "stringify open enum" {
    const SomeId = enum(usize) {
        _,
        pub fn jsonStringify(value: @This(), jws: anytype) !void {
            try jws.write(@intFromEnum(value));
        }
    };
    const json = try std.json.stringifyAlloc(std.testing.allocator, @as(SomeId, @enumFromInt(123)), .{});
    defer std.testing.allocator.free(json);
    try std.testing.expectEqualStrings("123", json);
}
