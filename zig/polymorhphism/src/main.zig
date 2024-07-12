const std = @import("std");

test {
    _ = @import("tagged_union.zig").Geometry;
    _ = @import("vtable.zig").Geometry;
    _ = @import("field_parent_ptr.zig").Geometry;
    _ = @import("anytype.zig").Circle;
    std.testing.refAllDeclsRecursive(@This());
}
