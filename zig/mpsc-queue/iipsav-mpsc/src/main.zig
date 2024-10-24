const std = @import("std");
const Atomic = std.atomic.Value;

fn Node(comptime T: type) type {
    return struct {
        value: T,
        next: ?*Node(T),
    };
}

pub const TaggedHead = packed struct {
    index: usize = 0,
    tag: usize = 0,
};

pub fn Channel(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        head: Atomic(u128),
        tail: Atomic(usize),
        buffer: [capacity]T = undefined,

        pub fn init(self: *Self) void {
            const head: u128 = @bitCast(TaggedHead{});
            self.head = Atomic(u128).init(head);
            self.tail = Atomic(usize).init(0);
        }

        pub fn send(self: *Self, value: T) !void {
            var old_tail = self.tail.load(.monotonic);
            var new_tail: usize = undefined;
            while (true) {
                new_tail = (old_tail + 1) % capacity;
                const head: TaggedHead = @bitCast(self.head.load(.monotonic));
                if (new_tail == head.index) {
                    return error.ChannelFull;
                }
                old_tail = self.tail.cmpxchgWeak(old_tail, new_tail, .release, .monotonic) orelse break;
            }
            self.buffer[old_tail] = value;
            self.tail.store(new_tail, .release);
        }

        pub fn recv(self: *Self) ?T {
            var old_tagged_head: TaggedHead = @bitCast(self.head.load(.acquire));
            while (true) {
                if (old_tagged_head.index == self.tail.load(.monotonic)) {
                    return null;
                }
                const new_head = TaggedHead{
                    .index = (old_tagged_head.index + 1) % capacity,
                    .tag = old_tagged_head.tag + 1,
                };
                if (self.head.cmpxchgWeak(@bitCast(old_tagged_head), @bitCast(new_head), .acquire, .monotonic)) |v| {
                    old_tagged_head = @bitCast(v);
                } else {
                    const value = self.buffer[old_tagged_head.index];
                    return value;
                }
            }
        }
    };
}

const MyUnion = union(enum) {
    foo: struct { entity_id: u128 = 0 },
    bar: struct { entity_id: u128 = 0 },
    baz: struct { entity_id: u128 = 0, component: u128 = 0 },
    fiz: struct { entity_id: u128 = 0, component_tag: u128 = 0 },
};

pub fn produce(channel: *Channel(MyUnion, count), value: MyUnion) void {
    channel.send(value) catch unreachable; // Benchmark is adjusted to not hit the limit.
}

const count = 131072;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var channel: Channel(MyUnion, count) = undefined;
    channel.init();
    var thread_pool: std.Thread.Pool = undefined;
    try std.Thread.Pool.init(&thread_pool, .{ .allocator = gpa.allocator() });
    var i: usize = 0;
    while (i < count) : (i += 1) {
        if (i % 4 == 0)
            try thread_pool.spawn(produce, .{ &channel, .{ .foo = .{ .entity_id = 123456 } } })
        else if (i % 4 == 1)
            try thread_pool.spawn(produce, .{ &channel, .{ .bar = .{ .entity_id = 123456 } } })
        else if (i % 4 == 2)
            try thread_pool.spawn(produce, .{ &channel, .{ .baz = .{ .entity_id = 123456, .component = 123456 } } })
        else if (i % 4 == 3)
            try thread_pool.spawn(produce, .{ &channel, .{ .fiz = .{ .entity_id = 123456, .component_tag = 123456 } } });
    }
    defer thread_pool.deinit();

    while (channel.recv()) |item| {
        _ = item;
    }
}
