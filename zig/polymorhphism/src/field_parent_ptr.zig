const std = @import("std");

/// Open interface type - anyone can extend.
///
/// Stores vtable on the struct instance, as a result can be
/// passed around as a single pointer (as opposed to fat pointer),
/// but each instance has to store vtable - more memory usage.
///
/// This has a caveat where the vtable HAS TO BE passed by ref,
/// otherwise you will make a copy and access random memory.
pub const Geometry = struct {
    pub const VTable = struct {
        area: *const fn (self: *Geometry) f32,
    };

    vtable: VTable,

    pub fn area(self: *Geometry) f32 {
        return self.vtable.area(self);
    }
};

pub const Rectangle = struct {
    width: f32,
    height: f32,
    geometry: Geometry,

    pub fn init(width: f32, height: f32) Rectangle {
        return .{
            .width = width,
            .height = height,
            .geometry = Geometry{
                .vtable = Geometry.VTable{
                    .area = &area,
                },
            },
        };
    }

    pub fn area(geometry: *Geometry) f32 {
        const self: *Rectangle = @fieldParentPtr("geometry", geometry);
        return self.width * self.height;
    }
};

pub const Circle = struct {
    radius: f32,
    geometry: Geometry,

    pub fn init(radius: f32) Circle {
        return .{
            .radius = radius,
            .geometry = Geometry{
                .vtable = Geometry.VTable{
                    .area = &area,
                },
            },
        };
    }

    pub fn area(geometry: *Geometry) f32 {
        const self: *Circle = @fieldParentPtr("geometry", geometry);
        return std.math.pi * std.math.pow(f32, self.radius, 2);
    }
};

test Geometry {
    var geometries = std.ArrayList(*Geometry).init(std.testing.allocator);
    defer geometries.deinit();

    var circle = Circle.init(2);
    var rectangle = Rectangle.init(2, 5);

    try geometries.append(&circle.geometry);
    try geometries.append(&rectangle.geometry);

    try std.testing.expectApproxEqRel(12.566, geometries.items[0].area(), 0.001);
    try std.testing.expectApproxEqRel(10, geometries.items[1].area(), 0.001);
}
