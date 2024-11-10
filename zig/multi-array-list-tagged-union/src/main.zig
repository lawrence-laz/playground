const std = @import("std");

const ComponentTag = enum {
    position,
    movement,
    health,
};

const Component = union(ComponentTag) {
    position: Position,
    movement: Movement,
    health: Health,
};

const Position = struct {
    x: f32,
    y: f32,
};

const Movement = struct {
    dir_x: f32,
    dir_y: f32,
    speed: f32,
};

const Health = struct {
    points: u32,
};

test "tagged union in multiarraylist" {
    var soa = std.MultiArrayList(Component){};
    defer soa.deinit(std.testing.allocator);

    try soa.append(std.testing.allocator, .{ .health = .{ .points = 100 } });
    try soa.append(std.testing.allocator, .{ .position = .{ .x = 1, .y = 0 } });
    try soa.append(std.testing.allocator, .{ .position = .{ .x = 100, .y = 0 } });
    try soa.append(std.testing.allocator, .{ .movement = .{ .dir_x = 1, .dir_y = 0, .speed = 100 } });

    const slice = soa.slice();

    // Count the number of fire monsters
    const total_x: usize = 0;
    // Eeh, for tagged unions it's just two arrays: tags and data.
    // Expected to have arrays for each tag.
    // for (slice.items(.position)) |position| {    // <-- this does not compile
    //     total_x += position.x;
    // }
    //
    // try std.testing.expectEqual(101, total_x);

    _ = slice;
    _ = total_x;
}

pub fn MultiArrayList(comptime T: type) type {
    return struct {
        lists: TagPayloadLists(T),

        pub fn ListType(comptime tag: std.meta.Tag(T)) type {
            return std.ArrayListUnmanaged(std.meta.TagPayload(T, tag));
        }

        pub fn init() MultiArrayList(T) {
            return .{ .lists = .{} };
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            inline for (std.meta.fields(T)) |field| {
                @field(self.lists, field.name).deinit(allocator);
            }
        }

        pub fn append(self: *@This(), allocator: std.mem.Allocator, item: T) !void {
            switch (item) {
                inline else => |payload, tag| {
                    var list = self.getPtr(tag);
                    try list.append(allocator, payload);
                },
            }
        }

        pub fn getPtr(self: *@This(), comptime tag: std.meta.Tag(T)) *ListType(tag) {
            return &@field(self.lists, @tagName(tag));
        }
    };
}

fn TagPayloadLists(comptime T: type) type {
    const field_count = std.meta.fields(T).len;
    var fields: [field_count]std.builtin.Type.StructField = undefined;
    inline for (std.meta.fields(T), 0..) |field, i| {
        const FieldType = field.type;
        const default_value: std.ArrayListUnmanaged(FieldType) = .{};
        fields[i] = std.builtin.Type.StructField{
            .name = field.name,
            .type = std.ArrayListUnmanaged(FieldType),
            .default_value = &default_value,
            .is_comptime = false,
            .alignment = @alignOf(std.ArrayListUnmanaged(FieldType)),
        };
    }
    return @Type(std.builtin.Type{
        .Struct = .{
            .fields = &fields,
            .decls = &.{},
            .layout = .auto,
            .is_tuple = false,
        },
    });
}

test "MulriArrayList for tagged union with list per tag" {
    var mal = MultiArrayList(Component).init();
    defer mal.deinit(std.testing.allocator);

    try mal.append(std.testing.allocator, .{ .health = .{ .points = 100 } });
    try mal.append(std.testing.allocator, .{ .position = .{ .x = 1, .y = 2 } });
    try mal.append(std.testing.allocator, .{ .health = .{ .points = 50 } });
    try mal.append(std.testing.allocator, .{ .health = .{ .points = 0 } });

    const healths = mal.getPtr(.health);
    const positions = mal.getPtr(.position);
    try std.testing.expectEqual(100, healths.items[0].points);
    try std.testing.expectEqual(50, healths.items[1].points);
    try std.testing.expectEqual(0, healths.items[2].points);
    try std.testing.expectEqual(1, positions.items[0].x);
    try std.testing.expectEqual(2, positions.items[0].y);
}
