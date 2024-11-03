const std = @import("std");

pub fn HotelList(comptime T: type) type {
    return struct {
        hotel: std.ArrayListUnmanaged(T) = .{},
        free_rooms: std.ArrayListUnmanaged(usize) = .{},

        const Iterator = struct {
            index: usize,
            list: *HotelList(T),

            pub fn init(list: *HotelList(T)) Iterator {
                return .{ .index = 0, .list = list };
            }

            pub fn next(self: *@This()) ?*T {
                while (std.mem.containsAtLeast(usize, self.list.free_rooms.items, 1, &.{self.index})) self.index += 1;
                if (self.index >= self.list.hotel.items.len) return null;
                const result_index = self.index;
                self.index += 1;
                return &self.list.hotel.items[result_index];
            }
        };

        pub fn iterator(self: *@This()) Iterator {
            return Iterator.init(self);
        }

        pub fn put(self: *@This(), allocator: std.mem.Allocator, item: T) !usize {
            if (self.free_rooms.popOrNull()) |free_index| {
                self.hotel.items[free_index] = item;
                return free_index;
            } else {
                try self.hotel.append(allocator, item);
                const new_index = self.hotel.items.len - 1;
                return new_index;
            }
        }

        pub fn remove(self: *@This(), allocator: std.mem.Allocator, index: usize) !void {
            std.debug.assert(self.hotel.items.len > index);
            std.debug.assert(!std.mem.containsAtLeast(usize, self.free_rooms.items, 1, &.{index}));
            try self.free_rooms.append(allocator, index);
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            self.hotel.deinit(allocator);
            self.free_rooms.deinit(allocator);
        }
    };
}

test HotelList {
    var sut: HotelList(u8) = .{};
    defer sut.deinit(std.testing.allocator);

    _ = try sut.put(std.testing.allocator, 'a');
    _ = try sut.put(std.testing.allocator, 'b');
    _ = try sut.put(std.testing.allocator, 'c');
    try std.testing.expectEqualStrings("abc", sut.hotel.items);

    var iter = sut.iterator();
    try std.testing.expectEqual('a', iter.next().?.*);
    try std.testing.expectEqual('b', iter.next().?.*);
    try std.testing.expectEqual('c', iter.next().?.*);

    try sut.remove(std.testing.allocator, 1);

    iter = sut.iterator();
    try std.testing.expectEqual('a', iter.next().?.*);
    try std.testing.expectEqual('c', iter.next().?.*);

    _ = try sut.put(std.testing.allocator, 'd');

    iter = sut.iterator();
    try std.testing.expectEqual('a', iter.next().?.*);
    try std.testing.expectEqual('d', iter.next().?.*);
    try std.testing.expectEqual('c', iter.next().?.*);
}
