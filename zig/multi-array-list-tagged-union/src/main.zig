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

    var slice = soa.slice();

    // Count the number of fire monsters
    var total_x: usize = 0;
    // Eeh, for tagged unions it's just two arrays: tags and data.
    // Expected to have arrays for each tag.
    for (slice.items(.position)) |position| {
        total_x += position.x;
    }

    try std.testing.expectEqual(101, total_x);
}
