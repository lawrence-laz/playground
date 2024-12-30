const std = @import("std");

fn functionWithError() !void {
    if (1 == 2) {
        return error.Oops;
    }
}

fn functionWithoutError() void {}

fn call(func: anytype) void {
    if (@typeInfo(@typeInfo(@TypeOf(func)).Fn.return_type.?) == .ErrorUnion) {
        func() catch {};
    } else {
        func();
    }
}

test "Check at comptime if function returns error" {
    call(functionWithError);
    call(functionWithoutError);
}

test "get hashmap key and value types" {
    var hashmap: std.AutoHashMapUnmanaged(u32, f32) = .{};
    defer hashmap.deinit(std.testing.allocator);

    try std.testing.expectEqual(@typeInfo(@typeInfo(@TypeOf(@TypeOf(hashmap).getKey)).Fn.return_type.?).Optional.child, u32);
    try std.testing.expectEqual(@typeInfo(@typeInfo(@TypeOf(@TypeOf(hashmap).get)).Fn.return_type.?).Optional.child, f32);
}

test "Get type of a ptr" {
    const Foo = struct { bar: usize };
    const foo: Foo = .{ .bar = 123 };
    const foo_ptr = &foo;
    const ptr_type_info = @typeInfo(@TypeOf(foo_ptr)).Pointer;
    try std.testing.expect(@hasField(ptr_type_info.child, "bar"));
}

test "Get fields by postfix" {
    const Foo = struct {
        hello: bool,
        bye: bool,

        aaa_system: usize,
        bbb_system: usize,
        ccc_system: usize,
    };
    inline for (std.meta.fields(Foo)) |field| {
        comptime if (!std.mem.endsWith(u8, field.name, "_system")) {
            if (!std.mem.eql(u8, field.name, "hello") and !std.mem.eql(u8, field.name, "bye")) {
                @compileError(field.name);
            }
        };
    }
}

test "Check if field is optional" {
    const Foo = struct {
        this_is_not_optional: i32,
        this_is_optional: ?i32,
    };

    var is_first_field_optional: ?bool = null;
    var is_second_field_optional: ?bool = null;

    inline for (std.meta.fields(Foo), 0..) |field, i| {
        const struct_field: std.builtin.Type.StructField = field;
        if (i == 0) {
            is_first_field_optional = std.meta.activeTag(@typeInfo(struct_field.type)) == .Optional;
        } else if (i == 1) {
            is_second_field_optional = std.meta.activeTag(@typeInfo(struct_field.type)) == .Optional;
        } else unreachable;
    }

    try std.testing.expectEqual(false, is_first_field_optional.?);
    try std.testing.expectEqual(true, is_second_field_optional.?);
}
