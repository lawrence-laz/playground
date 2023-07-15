const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "Add and remove from LinkedList" {
    var list = LinkedList(i32){
        .first = null,
        .last = null,
        .allocator = std.heap.page_allocator,
    };
    // var list = std.ArrayList(i32).init(std.testing.allocator);
    // defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.add(1);
    try list.add(2);
    try list.add(3);
    try testing.expectEqual(@as(usize, 3), list.length);
    try testing.expectEqual(true, list.remove(2));
    try testing.expectEqual(@as(usize, 2), list.length);
    try testing.expectEqual(false, list.remove(2));
    try testing.expectEqual(@as(usize, 2), list.length);
    try testing.expectEqual(true, list.remove(1));
    try testing.expectEqual(true, list.remove(3));
    try testing.expectEqual(@as(usize, 0), list.length);
}

fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            prev: ?*Node,
            next: ?*Node,
            data: T,
        };

        first: ?*Node,
        last: ?*Node,
        length: usize = 0,
        allocator: std.mem.Allocator,

        pub fn init() LinkedList {}

        pub fn add(list: *Self, item: T) !void {
            var new_node = try list.allocator.create(Node);
            errdefer list.allocator.destroy(new_node);
            new_node.* = .{ .next = null, .data = item, .prev = list.last };

            if (list.last == null and list.first == null) {
                list.first = new_node;
            } else {
                var last = list.last orelse unreachable;
                last.next = new_node;
            }
            list.last = new_node;

            list.length += 1;
        }

        pub fn remove(list: *Self, item: T) bool {
            // var current_node = list.first;
            var it: ?*const Node = list.first;
            while (it) |node| : (it = node.next) {
                // There are no guarantees, that the node.data is still there, the object might be gone and we just have a dangling pointer?
                if (node.data == item) {
                    std.debug.print("Remove found {}={}\n", .{ node.data, item });
                    if (list.first == node) {
                        list.first = node.next;
                    } else if (node.prev) |prev| {
                        prev.next = node.next;
                    }
                    list.length -= 1;
                    return true;
                }
            }
            return false;
        }

        pub fn deinit(self: Self) void {
            if (@sizeOf(T) > 0) {
                self.allocator.free(self.allocatedSlice());
            }
        }
    };
}
