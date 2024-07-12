const std = @import("std");

/// Open interface type - anyone can extend.
///
/// This is basically parameter ducktyping.
/// It does not allow storing instances in a covariant collection.
///
/// Very simple and fast though.
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

pub fn someFunction(geometry: anytype) f32 {
    return geometry.area();
}

test "Geometry as anytype" {
    var areas = std.ArrayList(f32).init(std.testing.allocator);
    defer areas.deinit();

    const circle = Circle{ .radius = 2 };
    const rectangle = Rectangle{ .width = 2, .height = 5 };

    try areas.append(someFunction(circle));
    try areas.append(someFunction(rectangle));

    try std.testing.expectApproxEqRel(12.566, areas.items[0], 0.001);
    try std.testing.expectApproxEqRel(10, areas.items[1], 0.001);
}
