const std = @import("std");
const StructField = std.builtin.Type.StructField;

// TODO
// pub fn SparseArrayHashMap(comptime K: type, comptime V: Type) !void {}

pub fn SparseMulti(comptime T: type) type {
    const t_fields = std.meta.fields(T);
    var arraylist_fields: [t_fields.len]StructField = undefined;
    inline for (t_fields, 0..) |field, i| {
        const struct_field = @as(StructField, field);
        arraylist_fields[i] = StructField{
            .name = struct_field.name,
            .type = std.ArrayList(struct_field.type),
            .default_value = null,
            .is_comptime = false,
            .alignment = @alignOf(std.ArrayList(struct_field.type)),
        };
    }

    const type_info: std.builtin.Type = .{
        .Struct = .{
            .layout = .auto,
            .decls = &.{},
            .is_tuple = false,
            .fields = &arraylist_fields,
        },
    };

    return @Type(type_info);
}

test "Convert a struct with optional fields into a struct of sparce arrays" {
    const Foo = struct {
        foo_field: u32,
    };

    const Bar = struct {
        bar_field: bool,
    };

    const Baz = struct {
        baz_field: []const u8,
    };

    const MyStruct = struct {
        foo: ?Foo,
        bar: ?Bar,
        baz: ?Baz,
    };

    const MyStructAsArrays = SparseMulti(MyStruct);

    var instance = MyStructAsArrays{
        .foo = std.ArrayList(?Foo).init(std.testing.allocator),
        .bar = std.ArrayList(?Bar).init(std.testing.allocator),
        .baz = std.ArrayList(?Baz).init(std.testing.allocator),
    };
    defer {
        instance.foo.deinit();
        instance.bar.deinit();
        instance.baz.deinit();
    }

    try instance.foo.append(.{ .foo_field = 123 });
    try instance.bar.append(.{ .bar_field = true });
    try instance.bar.append(.{ .bar_field = false });
    try instance.baz.append(.{ .baz_field = "hello" });
    try std.testing.expectEqual(1, instance.foo.items.len);

    try std.testing.expectEqual(123, instance.foo.items[0].?.foo_field);

    try std.testing.expectEqual(2, instance.bar.items.len);
    try std.testing.expectEqual(true, instance.bar.items[0].?.bar_field);
    try std.testing.expectEqual(false, instance.bar.items[1].?.bar_field);

    try std.testing.expectEqual(1, instance.baz.items.len);
    try std.testing.expectEqualStrings("hello", instance.baz.items[0].?.baz_field);
}
