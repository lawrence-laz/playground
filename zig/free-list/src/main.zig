const std = @import("std");

pub fn FreeList(comptime T: type) type {
    return struct {
        pub const Item = union(enum) { free: ?usize, value: T };

        pub const Iterator = struct {
            index: usize = 0,
            list: *const FreeList(T),

            pub fn next(iterator: *Iterator) ?T {
                while (true) {
                    defer iterator.index += 1;

                    if (iterator.index >= iterator.list.data.items.len) {
                        return null;
                    }

                    switch (iterator.list.data.items[iterator.index]) {
                        .free => continue,
                        .value => |value| return value,
                    }
                }
            }
        };

        data: std.ArrayListUnmanaged(Item) = .{},
        maybe_free_index: ?usize = null,

        pub fn add(list: *@This(), allocator: std.mem.Allocator, item: T) !usize {
            if (list.maybe_free_index) |free_index| {
                list.maybe_free_index = list.data.items[free_index].free;
                list.data.items[free_index] = .{ .value = item };
                return free_index;
            }

            try list.data.append(allocator, .{ .value = item });
            return list.data.items.len;
        }

        pub fn removeAt(list: *FreeList(T), index: usize) void {
            list.data.items[index] = .{ .free = list.maybe_free_index };
            list.maybe_free_index = index;
        }

        pub fn iter(list: *const FreeList(T)) Iterator {
            return .{ .list = list };
        }

        pub fn deinit(list: *FreeList(T), allocator: std.mem.Allocator) void {
            list.data.deinit(allocator);
        }
    };
}

test FreeList {
    {
        var list: FreeList(i32) = .{};
        defer list.deinit(std.testing.allocator);

        _ = try list.add(std.testing.allocator, 1);
        _ = try list.add(std.testing.allocator, 2);
        _ = try list.add(std.testing.allocator, 3);

        var iter = list.iter();
        try std.testing.expectEqual(1, iter.next().?);
        try std.testing.expectEqual(2, iter.next().?);
        try std.testing.expectEqual(3, iter.next().?);

        list.removeAt(1);

        iter = list.iter();
        try std.testing.expectEqual(1, iter.next().?);
        try std.testing.expectEqual(3, iter.next().?);

        _ = try list.add(std.testing.allocator, 4);
        iter = list.iter();
        try std.testing.expectEqual(1, iter.next().?);
        try std.testing.expectEqual(4, iter.next().?);
        try std.testing.expectEqual(3, iter.next().?);
    }
}