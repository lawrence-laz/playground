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
