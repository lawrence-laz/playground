const std = @import("std");
const StructField = std.builtin.Type.StructField;

test "simple test" {
    const type_info: std.builtin.Type = .{
        .Struct = .{
            .layout = .auto,
            .decls = &.{},
            .is_tuple = false,
            .fields = &[_]StructField{
                StructField{
                    .name = "foo",
                    .type = u32,
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = 0,
                },
                StructField{
                    .name = "bar",
                    .type = bool,
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = 0,
                },
            },
        },
    };

    const SomeType = @Type(type_info);

    const some_type_instance = SomeType{ .foo = 123, .bar = true };

    try std.testing.expectEqual(123, some_type_instance.foo);
    try std.testing.expectEqual(true, some_type_instance.bar);
}
