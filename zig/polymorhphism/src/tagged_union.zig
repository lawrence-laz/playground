const std = @import("std");

/// Closed interface type - only types defined here can be used.
/// Very simple and very fast.
pub const Geometry = union(enum) {
    rectangle: Rectangle,
    circle: Circle,

    pub fn area(self: Geometry) f32 {
        return switch (self) {
            inline else => |concrete| concrete.area(),
        };
    }
};

pub const Rectangle = struct {
    width: f32,
    height: f32,

    pub fn area(self: Rectangle) f32 {
        return self.width * self.height;
    }
};

pub const Circle = struct {
    radius: f32,

    pub fn area(self: Circle) f32 {
        return std.math.pi * std.math.pow(f32, self.radius, 2);
    }
};

test Geometry {
    var geometries = std.ArrayList(Geometry).init(std.testing.allocator);
    defer geometries.deinit();

    try geometries.append(Geometry{ .circle = .{ .radius = 2 } });
    try geometries.append(Geometry{ .rectangle = .{ .width = 2, .height = 5 } });

    try std.testing.expectApproxEqRel(12.566, geometries.items[0].area(), 0.001);
    try std.testing.expectApproxEqRel(10, geometries.items[1].area(), 0.001);
}
