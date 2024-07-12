const std = @import("std");

/// Open interface type - anyone can extend.
pub const Geometry = struct {
    pub const VTable = struct {
        area: *const fn (ctx: *anyopaque) f32,
    };

    ptr: *anyopaque,
    vtable: *const VTable,

    pub fn area(self: Geometry) f32 {
        return self.vtable.area(self.ptr);
    }
};

pub const Rectangle = struct {
    width: f32,
    height: f32,

    pub fn area(self_opaque: *anyopaque) f32 {
        const self: *Rectangle = @ptrCast(@alignCast(self_opaque));
        return self.width * self.height;
    }

    const vtable = Geometry.VTable{
        .area = &area,
    };

    pub fn geometry(self: *Rectangle) Geometry {
        return .{
            .ptr = @ptrCast(self),
            .vtable = &vtable,
        };
    }
};

pub const Circle = struct {
    radius: f32,

    pub fn area(self_opaque: *anyopaque) f32 {
        const self: *Circle = @ptrCast(@alignCast(self_opaque));
        return std.math.pi * std.math.pow(f32, self.radius, 2);
    }

    const vtable = Geometry.VTable{
        .area = &area,
    };

    pub fn geometry(self: *Circle) Geometry {
        return .{
            .ptr = @ptrCast(self),
            .vtable = &vtable,
        };
    }
};

test Geometry {
    var geometries = std.ArrayList(Geometry).init(std.testing.allocator);
    defer geometries.deinit();

    var circle = Circle{ .radius = 2 };
    var rectangle = Rectangle{ .width = 2, .height = 5 };

    try geometries.append(circle.geometry());
    try geometries.append(rectangle.geometry());

    try std.testing.expectApproxEqRel(12.566, geometries.items[0].area(), 0.001);
    try std.testing.expectApproxEqRel(10, geometries.items[1].area(), 0.001);
}
