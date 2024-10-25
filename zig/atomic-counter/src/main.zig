const std = @import("std");

const AtomicCounter = struct {
    count: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),

    pub fn increment(self: *@This()) usize {
        return self.count.fetchAdd(1, .monotonic);
    }
};

fn doWork(counter: *AtomicCounter) void {
    var i: usize = 0;
    while (i < 10000) : (i += 1) {
        _ = counter.increment();
    }
}

test "simple test" {
    var counter: AtomicCounter = .{};
    var thread_pool: std.Thread.Pool = undefined;
    try std.Thread.Pool.init(&thread_pool, .{ .allocator = std.testing.allocator });
    defer thread_pool.deinit();
    var wait: std.Thread.WaitGroup = .{};
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        thread_pool.spawnWg(&wait, doWork, .{&counter});
    }
    wait.wait();
    try std.testing.expectEqual(1000000, counter.count.raw);
}
