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
