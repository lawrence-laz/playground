const ComponentTag = enum { foo, bar, baz };
const Component = union(ComponentTag) { foo: void, bar: void, baz: void };

fn acceptTag(tag: ComponentTag) void {
    _ = tag;
}

test "coerce Component into ComponentTag" {
    const component: Component = .{ .foo = {} };
    acceptTag(component);
}

fn acceptTags(tags: []const ComponentTag) void {
    _ = tags;
}

test "coerce []const Component into []const ComponentTag" {
    acceptTags(components); // expected type '[]const main.ComponentTag', found '[]const main.Component
}
