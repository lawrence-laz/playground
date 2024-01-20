const std = @import("std");

const DummyPipelineStep = struct {
    fn send(
        self: @This(),
        message: anytype,
    ) void {
        _ = message;
        _ = self;
    }
};

fn PipelineStep(
    comptime TCurrent: type,
    comptime TNext: type,
) type {
    return struct {
        current: TCurrent,
        next: ?TNext = null,

        inline fn prepend(
            self: @This(),
            step: anytype,
        ) PipelineStep(@TypeOf(step), @This()) {
            return .{
                .current = step,
                .next = self,
            };
        }

        fn send(
            self: @This(),
            message: anytype,
        ) void {
            self.current.handle(message, self.next);
            // if (self.next) |next_step| {
            //     next_step.send(message);
            // }
        }
    };
}

pub fn pipeline(step: anytype) PipelineStep(@TypeOf(step), DummyPipelineStep) {
    return .{
        .current = step,
        .next = null,
    };
}

const SomeMessage = struct {
    foo: bool,
    bar: bool,
};

const Foo = struct {
    pub fn handle(self: Foo, message: anytype, next: anytype) void {
        _ = self;
        message.foo = true;
        if (next) |next_step| {
            next_step.send(message);
        }
    }
};

const Bar = struct {
    pub fn handle(self: Bar, message: anytype, next: anytype) void {
        _ = self;
        message.bar = true;
        if (next) |next_step| {
            next_step.send(message);
        }
    }
};

test PipelineStep {
    var message = SomeMessage{
        .foo = false,
        .bar = false,
    };
    const sut = pipeline(Foo{}).prepend(Bar{});
    sut.send(&message);
    try std.testing.expectEqual(message.foo, true);
    try std.testing.expectEqual(message.bar, true);
}
