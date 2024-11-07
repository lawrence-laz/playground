const std = @import("std");

const SomeTag = enum { foo, bar, baz };
const SomeUnion = union(SomeTag) {
    foo: Foo,
    bar: Bar,
    baz: Baz,
};
const Foo = struct { foo1: i32, foo2: i32 };
const Bar = struct { bar1: bool };
const Baz = struct { baz: f32 };

test "Something like 'TaggedUnionSet' via std.EnumMap(Tag, Union)" {
    const map = std.EnumMap(SomeTag, SomeUnion).init(.{ .foo = .{ .foo = .{ .foo1 = 123, .foo2 = 456 } } });
    try std.testing.expectEqual(123, map.get(.foo).?.foo.foo1);
    try std.testing.expectEqual(456, map.get(.foo).?.foo.foo2);
}
