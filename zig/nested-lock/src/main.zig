const std = @import("std");

// https://ziglang.org/documentation/master/std/#std.Thread.Mutex.Recursive
// std.Thread.Mutext.Recursive is not in 0.13.0 :(
var mutext: std.Thread.Mutex = .{};

pub fn foo() i32 {
    mutext.lock();
    defer mutext.unlock();
    return 123;
}

pub fn bar() i32 {
    mutext.lock();
    defer mutext.unlock();
    const my_foo = foo();
    return my_foo + 123;
}

test "simple test" {
    try std.testing.expectEqual(246, bar());
}
