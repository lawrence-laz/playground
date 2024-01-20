const std = @import("std");

const FooAction = struct {
    foo: u8,
    was_behavior_called: bool,
    was_handler_called: bool,
};

pub fn callNext(next: anytype) void {
    _ = next;
}

pub fn SomeBehavior(comptime TNext: type) type {
    return struct {
        next: TNext,
        pub fn handle(self: @This(), message: anytype) void {
            message.was_behavior_called = true;
            self.next.handle(message);
        }
    };
}

const FooHandler = struct {
    fn handle(self: FooHandler, action: *FooAction) void {
        _ = self;
        action.foo += 1;
        action.was_handler_called = true;
    }
};

const Pipeline = struct {
    //
};

test FooAction {
    const pipeline = SomeBehavior(FooHandler){ .next = FooHandler{} };
    var message = FooAction{
        .foo = 0,
        .was_behavior_called = false,
        .was_handler_called = false,
    };
    pipeline.handle(&message);
    try std.testing.expectEqual(message.was_handler_called, true);
    try std.testing.expectEqual(message.was_behavior_called, true);
    try std.testing.expectEqual(message.foo, 1);
}

const Bar = struct {
    pub fn bar(self: Bar) void {
        _ = self;
    }
};

test "call on anyopaque" {
    const bar = Bar{};
    var bar_2: anyopaque = bar;
    bar_2.bar();
}
