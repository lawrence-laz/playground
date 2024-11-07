const std = @import("std");

pub fn MultiTagArrayList(comptime TaggedUnionType: type) type {
    return struct {
        lists: TagPayloadLists(TaggedUnionType),

        pub fn ListType(comptime tag: std.meta.Tag(TaggedUnionType)) type {
            return std.ArrayListUnmanaged(std.meta.TagPayload(TaggedUnionType, tag));
        }

        pub fn init() MultiTagArrayList(TaggedUnionType) {
            return .{ .lists = .{} };
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            inline for (std.meta.fields(TaggedUnionType)) |field| {
                @field(self.lists, field.name).deinit(allocator);
            }
        }

        pub fn append(self: *@This(), allocator: std.mem.Allocator, item: TaggedUnionType) !void {
            switch (item) {
                inline else => |payload, tag| {
                    var list = self.getPtr(tag);
                    try list.append(allocator, payload);
                },
            }
        }

        pub fn count(self: *const @This(), tag: std.meta.Tag(TaggedUnionType)) usize {
            switch (tag) {
                inline else => |t| return @field(self.lists, @tagName(t)).items.len,
            }
        }

        pub fn getPtr(self: *@This(), comptime tag: std.meta.Tag(TaggedUnionType)) *ListType(tag) {
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

test MultiTagArrayList {
    const ComponentTag = enum {
        position,
        movement,
        health,
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

    const Component = union(ComponentTag) {
        position: Position,
        movement: Movement,
        health: Health,
    };

    var list = MultiTagArrayList(Component).init();
    defer list.deinit(std.testing.allocator);

    try list.append(std.testing.allocator, .{ .health = .{ .points = 100 } });
    try list.append(std.testing.allocator, .{ .position = .{ .x = 1, .y = 2 } });
    try list.append(std.testing.allocator, .{ .health = .{ .points = 50 } });
    try list.append(std.testing.allocator, .{ .health = .{ .points = 0 } });

    const healths = list.getPtr(.health);
    try std.testing.expectEqual(100, healths.items[0].points);
    try std.testing.expectEqual(50, healths.items[1].points);
    try std.testing.expectEqual(0, healths.items[2].points);

    const positions = list.getPtr(.position);
    try std.testing.expectEqual(1, positions.items[0].x);
    try std.testing.expectEqual(2, positions.items[0].y);
}
