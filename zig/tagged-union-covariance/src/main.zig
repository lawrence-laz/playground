const std = @import("std");

const ComponentTag = enum { foo, bar, baz };
const Component = union(ComponentTag) {
    foo: Foo,
    bar: Bar,
    baz: Baz,
};
const Foo = struct { foo: i32 };
const Bar = struct { bar: i32, bar2: bool };
const Baz = struct { baz: []const u8 };

test "simple test" {
    // As long as the list is using the union type and not active tag type directly, there is no issue.
    // Kind of the point of tagged unions, right?
    const list = std.ArrayListUnmanaged(Component){};
    var list_of_lists = std.ArrayListUnmanaged(std.ArrayListUnmanaged(Component)){};
    defer list_of_lists.deinit(std.testing.allocator);
    try list_of_lists.append(std.testing.allocator, list);
}
