const std = @import("std");
const Atomic = std.atomic.Value;

fn Node(T: type) type {
    return struct {
        next: Atomic(?*Node(T)) = Atomic(?*Node(T)).init(null),
        value: T,
    };
}

fn MpscQueue(T: type) type {
    return struct {
        stub: Node(T),
        head: Atomic(*Node(T)),
        tail: Atomic(*Node(T)),

        pub fn init(queue: *MpscQueue(T)) void {
            queue.stub = .{ .value = .{ .foo = .{} } };
            queue.head = Atomic(*Node(T)).init(&queue.stub);
            queue.tail = Atomic(*Node(T)).init(&queue.stub);
            queue.stub.next.store(null, .seq_cst);
        }

        pub fn push(self: *@This(), node: *Node(T)) void {
            node.next.store(null, .monotonic);
            var prev = self.tail.swap(node, .seq_cst);
            prev.next.store(node, .release);
        }

        pub fn pop(self: *@This()) ?*Node(T) {
            var head_copy = self.head.load(.seq_cst);
            const maybe_next = head_copy.next.load(.monotonic);
            if (maybe_next) |next| {
                self.head.store(next, .unordered);
                head_copy.value = next.value;
                return head_copy;
            }
            return null;
        }
    };
}
const MyUnion = union(enum) {
    foo: struct { entity_id: u128 = 0 },
    bar: struct { entity_id: u128 = 0 },
    baz: struct { entity_id: u128 = 0, component: u128 = 0 },
    fiz: struct { entity_id: u128 = 0, component_tag: u128 = 0 },
};

pub fn produce(queue: *MpscQueue(MyUnion), value: *Node(MyUnion)) void {
    queue.push(value);
}

const count = 131072;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var items: [count]Node(MyUnion) = undefined;
    var a: usize = 0;
    while (a < count) : (a += 1) items[a] = .{ .value = .{ .foo = .{ .entity_id = 123456 } } };
    // .{ .next = null, .value = .{ .foo = .{ .entity_id = 123456 } } } ** count;
    var queue: MpscQueue(MyUnion) = undefined;
    queue.init();
    var thread_pool: std.Thread.Pool = undefined;
    defer thread_pool.deinit();
    try std.Thread.Pool.init(&thread_pool, .{ .allocator = gpa.allocator() });
    const start_time = std.time.nanoTimestamp();
    var i: usize = 0;
    while (i < count) : (i += 1) {
        try thread_pool.spawn(produce, .{ &queue, &items[i] });
    }

    while (queue.pop()) |item| {
        _ = item;
    }
    const end_time = std.time.nanoTimestamp();
    std.debug.print("TOTAL TIME: {}\n", .{std.fmt.fmtDuration(@intCast(end_time - start_time))});
}
