const std = @import("std");

const Ecs = struct {
    world: World,
    archetypes: Archetypes,
    component_archetype_index: ComponentArchetypeIndexTable,

    pub fn init(allocator: std.mem.Allocator) !Ecs {
        return .{
            .world = .{},
            .archetypes = try Archetypes.init(allocator),
            .component_archetype_index = ComponentArchetypeIndexTable.init(),
        };
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.component_archetype_index.deinit(allocator);
        self.archetypes.deinit(allocator);
        self.world.area.entities.rows.deinit(allocator);
    }

    pub fn createEntity(self: *@This(), allocator: std.mem.Allocator) !EntityId {
        self.world.area.entities.lock.lock();
        defer self.world.area.entities.lock.unlock();
        const entity_id: EntityId = @enumFromInt(self.world.area.entities.rows.count());
        try self.world.area.entities.rows.put(allocator, entity_id, .{
            .archetype_id = Archetypes.identity_id,
            .entity_row_id = @enumFromInt(0), // Identity archetype has no rows.
        });
        return entity_id;
    }

    pub fn getArchetypeIdForComponentTags(self: *@This(), component_tags: []const ComponentTag) ?ArchetypeId {
        for (self.archetypes.rows.values()) |archetype| {
            const contains_all_components = blk: {
                for (component_tags) |component_tag| {
                    if (!std.mem.containsAtLeast(ComponentTag, archetype.component_tags.items, 1, &.{component_tag})) {
                        break :blk false;
                    }
                }
                break :blk true;
            };
            if (contains_all_components) {
                return archetype.id;
            }
        }
        return null;
    }
};

const Archetypes = struct {
    pub const identity_id: ArchetypeId = @enumFromInt(0);

    rows: std.AutoArrayHashMapUnmanaged(ArchetypeId, Archetype) = .{},

    pub fn init(allocator: std.mem.Allocator) !Archetypes {
        var archetypes: Archetypes = .{};
        try archetypes.rows.put(allocator, identity_id, .{ .id = @enumFromInt(archetypes.rows.count()) });
        return archetypes;
    }

    pub fn getPtr(self: @This(), id: ArchetypeId) *Archetype {
        return self.rows.getPtr(id).?;
    }

    pub fn get(self: @This(), id: ArchetypeId) *Archetype {
        return self.rows.get(id);
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.rows.deinit(allocator);
    }
};

const ArchetypeId = enum(usize) {
    _,
    pub fn jsonStringify(value: @This(), jws: anytype) !void {
        try jws.write(@intFromEnum(value));
    }
};

const Archetype = struct {
    id: ArchetypeId,
    component_tags: std.ArrayListUnmanaged(ComponentTag) = .{},
    super_archetypes: std.AutoHashMapUnmanaged(ComponentTag, ArchetypeId) = .{},
    sub_archetypes: std.AutoHashMapUnmanaged(ComponentTag, ArchetypeId) = .{},

    pub fn getOrCreateSuperArchetypeId(
        self: *@This(),
        allocator: std.mem.Allocator,
        component_tag_to_add: ComponentTag,
        ecs: *Ecs,
    ) !ArchetypeId {
        std.debug.assert(!std.mem.containsAtLeast(ComponentTag, self.component_tags.items, 1, &.{component_tag_to_add}));
        if (self.super_archetypes.get(component_tag_to_add)) |super_archetype_id| {
            return super_archetype_id;
        }
        var super_archetype: Archetype = .{ .id = @enumFromInt(ecs.archetypes.rows.count()) };
        try super_archetype.component_tags.appendSlice(allocator, self.component_tags.items);
        try super_archetype.component_tags.append(allocator, component_tag_to_add);
        try super_archetype.sub_archetypes.put(allocator, component_tag_to_add, self.id);
        try ecs.archetypes.rows.put(allocator, super_archetype.id, super_archetype);
        _ = try ArchetypeTable.init(allocator, super_archetype.id, ecs);
        try self.super_archetypes.put(allocator, component_tag_to_add, super_archetype.id);
        return super_archetype.id;
    }

    pub fn getOrCreateSubArchetypeId(
        self: *@This(),
        allocator: std.mem.Allocator,
        component_tag_to_remove: ComponentTag,
        ecs: *Ecs,
    ) !ArchetypeId {
        std.debug.assert(std.mem.containsAtLeast(ComponentTag, self.component_tags.items, 1, &.{component_tag_to_remove}));
        if (self.sub_archetypes.get(component_tag_to_remove)) |sub_archetype_id| {
            return sub_archetype_id;
        }
        var sub_archetype: Archetype = .{ .id = @enumFromInt(ecs.archetypes.rows.count()) };

        for (self.component_tags.items) |component_tag| {
            if (component_tag == component_tag_to_remove) {
                continue;
            }
            try sub_archetype.component_tags.append(allocator, component_tag);
        }

        try sub_archetype.super_archetypes.put(allocator, component_tag_to_remove, self.id);
        try ecs.archetypes.rows.put(allocator, sub_archetype.id, sub_archetype);
        _ = try ArchetypeTable.init(allocator, sub_archetype.id, ecs);
        try self.super_archetypes.put(allocator, component_tag_to_remove, sub_archetype.id);
        return sub_archetype.id;
    }
};

const ComponentTag = enum(usize) { foo, bar, baz };

const Component = union(ComponentTag) {
    foo: Foo,
    bar: Bar,
    baz: Baz,

    const count = @typeInfo(ComponentTag).Enum.fields.len;
};
const Foo = struct { foo: i32 };
const Bar = struct { bar: i32, bar2: bool };
const Baz = struct { baz: []const u8 };

const World = struct {
    area: Area = .{},
};

const Area = struct {
    id: usize = 0, // Ulid
    entities: EntityArchetypeIndexTable = .{},
    components: ArchetypeTables = .{},
};

const EntityArchetypeIndexTable = struct {
    rows: std.AutoHashMapUnmanaged(EntityId, EntityArchetypeIndexRow) = .{},
    lock: std.Thread.RwLock = .{},

    pub fn getPtr(self: @This(), entity_id: EntityId) *EntityArchetypeIndexRow {
        return self.rows.getPtr(entity_id).?;
    }

    pub fn get(self: @This(), entity_id: EntityId) *EntityArchetypeIndexRow {
        return self.rows.get(entity_id).?;
    }
};

const EntityId = enum(usize) {
    _,

    pub fn jsonStringify(value: @This(), jws: anytype) !void {
        try jws.write(@intFromEnum(value));
    }

    pub fn addComponent(
        self: EntityId,
        allocator: std.mem.Allocator,
        component: Component,
        ecs: *Ecs,
    ) !void {
        try self.addComponents(allocator, &.{component}, ecs);
    }

    pub fn addComponents(
        self: EntityId,
        allocator: std.mem.Allocator,
        components: []const Component,
        ecs: *Ecs,
    ) !void {
        ecs.world.area.entities.lock.lock();
        defer ecs.world.area.entities.lock.unlock();
        const entity = ecs.world.area.entities.getPtr(self);
        const current_archetype = ecs.archetypes.getPtr(entity.archetype_id);
        for (components) |component| {
            if (std.mem.containsAtLeast(ComponentTag, current_archetype.component_tags.items, 1, &.{component})) {
                return;
            }
        }

        // Change archetype.
        const prev_archetype_id = entity.archetype_id;
        const prev_archetype = current_archetype;
        const new_archetype_id = blk: {
            var archetype = prev_archetype;
            for (components) |component| {
                const id = try archetype.getOrCreateSuperArchetypeId(allocator, component, ecs);
                archetype = ecs.archetypes.getPtr(id);
            }
            break :blk archetype.id;
        };
        const new_archetype_table = ecs.world.area.components.getPtr(new_archetype_id).?;
        entity.archetype_id = new_archetype_id;

        // Assume last row id in the new archetype table.
        const prev_entity_row_id = entity.entity_row_id;
        entity.entity_row_id = @enumFromInt(new_archetype_table.columns.items[0].rows.items.len);

        const maybe_prev_archetype_table = ecs.world.area.components.getPtr(prev_archetype_id);
        if (maybe_prev_archetype_table) |prev_archetype_table| {
            // Replace last row's id in the prev archetype, since it will be swap removed.
            const last_entity_row_id = prev_archetype_table.columns.items[0].rows.items.len - 1;
            var last_entity = ecs.world.area.entities.getPtr(@enumFromInt(last_entity_row_id));
            last_entity.entity_row_id = prev_entity_row_id;

            // Move component data from prev archetype table to the new one.
            for (prev_archetype_table.columns.items) |*column| {
                const removed_component = column.rows.swapRemove(@intFromEnum(prev_entity_row_id));
                const new_column_id = ecs.component_archetype_index.get(new_archetype_id, column.tag).component_column_id;
                var new_archetype_table_rows = &new_archetype_table.getColumnPtr(new_column_id).rows;
                try new_archetype_table_rows.append(allocator, removed_component);
            }
        }

        // Add the new components
        for (components) |component| {
            const column_id = ecs.component_archetype_index.get(new_archetype_id, component).component_column_id;
            try new_archetype_table.getColumnPtr(column_id).rows.append(allocator, component);
        }
    }

    pub fn removeComponent(
        self: EntityId,
        allocator: std.mem.Allocator,
        component_tag_to_remove: ComponentTag,
        ecs: *Ecs,
    ) !void {
        const entity = ecs.world.area.entities.getPtr(self);
        const archetype = ecs.archetypes.getPtr(entity.archetype_id);
        if (!std.mem.containsAtLeast(ComponentTag, archetype.component_tags.items, 1, &.{component_tag_to_remove})) {
            return;
        }

        // Change archetype.
        const prev_archetype_id = entity.archetype_id;
        const prev_archetype = archetype;
        const new_archetype_id = try prev_archetype.getOrCreateSubArchetypeId(allocator, component_tag_to_remove, ecs);
        const new_archetype_table = ecs.world.area.components.getPtr(new_archetype_id).?;
        entity.archetype_id = new_archetype_id;

        // Assume last row id in the new archetype table.
        const prev_entity_row_id = entity.entity_row_id;
        entity.entity_row_id = @enumFromInt(new_archetype_table.columns.items[0].rows.items.len);

        const maybe_prev_archetype_table = ecs.world.area.components.getPtr(prev_archetype_id);
        if (maybe_prev_archetype_table) |prev_archetype_table| {
            // Replace last row's id in the prev archetype, since it will be swap removed.
            const last_entity_row_id = prev_archetype_table.columns.items[0].rows.items.len - 1;
            var last_entity = ecs.world.area.entities.getPtr(@enumFromInt(last_entity_row_id));
            last_entity.entity_row_id = prev_entity_row_id;

            // Move component data from prev archetype table to the new one.
            for (prev_archetype_table.columns.items) |*column| {
                const removed_component = column.rows.swapRemove(@intFromEnum(prev_entity_row_id));
                if (column.tag == component_tag_to_remove) {
                    // The removed component is not added to the new table.
                    continue;
                }
                const new_column_id = ecs.component_archetype_index.get(new_archetype_id, column.tag).component_column_id;
                var new_archetype_table_rows = &new_archetype_table.getColumnPtr(new_column_id).rows;
                try new_archetype_table_rows.append(allocator, removed_component);
            }
        }
    }

    pub fn getComponent(self: EntityId, component_tag: ComponentTag, ecs: *const Ecs) ?Component {
        const entity = ecs.world.area.entities.getPtr(self);
        const column_id = ecs.component_archetype_index.get(entity.archetype_id, component_tag).component_column_id;
        return ecs.world.area.components
            .getPtr(entity.archetype_id).?
            .getColumnPtr(column_id)
            .rows.items[@intFromEnum(entity.entity_row_id)];
    }

    pub fn getArchetypeId(self: EntityId, ecs: *const Ecs) ArchetypeId {
        return ecs.world.area.entities.getPtr(self).archetype_id;
    }
};

const EntityArchetypeIndexRow = struct {
    archetype_id: ArchetypeId,
    entity_row_id: EntityRowId,
};

const EntityRowId = enum(usize) {
    _,

    pub fn jsonStringify(value: @This(), jws: anytype) !void {
        try jws.write(@intFromEnum(value));
    }
};

const ComponentArchetypeIndexTable = struct {
    rows: [Component.count]std.AutoHashMapUnmanaged(ArchetypeId, ComponentArchetypeIndexRow) = .{.{}} ** Component.count,

    pub fn init() @This() {
        return .{};
    }

    pub fn get(self: @This(), archetype_id: ArchetypeId, component_tag: ComponentTag) ComponentArchetypeIndexRow {
        const index = @intFromEnum(component_tag);
        return self.rows[index].get(archetype_id).?;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        for (&self.rows) |*item| {
            item.deinit(allocator);
        }
    }
};

const ComponentArchetypeIndexRow = struct {
    component_column_id: ComponentColumnId,
};

const ArchetypeTables = struct {
    tables: std.AutoArrayHashMapUnmanaged(ArchetypeId, ArchetypeTable) = .{},

    pub fn getPtr(self: *const @This(), archetype_id: ArchetypeId) ?*ArchetypeTable {
        return self.tables.getPtr(archetype_id);
    }

    pub fn get(self: *const @This(), archetype_id: ArchetypeId) ?*ArchetypeTable {
        return self.tables.get(archetype_id);
    }
};

const ArchetypeTable = struct {
    columns: std.ArrayListUnmanaged(ComponentColumn) = .{},

    pub fn init(allocator: std.mem.Allocator, archetype_id: ArchetypeId, ecs: *Ecs) !ArchetypeTable {
        var table: ArchetypeTable = .{};
        const archetype = ecs.archetypes.getPtr(archetype_id);
        for (archetype.component_tags.items, 0..) |component_tag, i| {
            try table.columns.append(allocator, .{ .tag = component_tag });
            try ecs.component_archetype_index
                .rows[@intFromEnum(component_tag)]
                .put(allocator, archetype.id, .{ .component_column_id = @enumFromInt(i) });
        }
        try ecs.world.area.components.tables.put(allocator, archetype.id, table);
        return table;
    }

    pub fn getColumnPtr(self: @This(), component_column_id: ComponentColumnId) *ComponentColumn {
        return &self.columns.items[@intFromEnum(component_column_id)];
    }
};

const ComponentColumnId = enum(usize) {
    _,

    pub fn jsonStringify(value: @This(), jws: anytype) !void {
        try jws.write(@intFromEnum(value));
    }
};

const ComponentColumn = struct {
    tag: ComponentTag,
    rows: std.ArrayListUnmanaged(Component) = .{},
};

test "archetypes of components of entities" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var ecs = try Ecs.init(arena.allocator());
    defer ecs.deinit(arena.allocator());

    // TODO: handle locking (do test with threads?)
    const foobar_entity = try ecs.createEntity(arena.allocator());
    try foobar_entity.addComponents(arena.allocator(), &.{
        .{ .foo = .{ .foo = 1 } },
        .{ .bar = .{ .bar = 456, .bar2 = true } },
    }, &ecs);

    // Adding and removing some component.
    try foobar_entity.addComponent(arena.allocator(), .{ .baz = .{ .baz = "woo" } }, &ecs);
    try foobar_entity.removeComponent(arena.allocator(), .baz, &ecs);

    const foobar_entity2 = try ecs.createEntity(arena.allocator());
    try foobar_entity2.addComponents(arena.allocator(), &.{
        .{ .foo = .{ .foo = 2 } },
        .{ .bar = .{ .bar = 456, .bar2 = true } },
    }, &ecs);

    try std.testing.expect(foobar_entity != foobar_entity2);
    try std.testing.expectEqual(foobar_entity.getArchetypeId(&ecs), foobar_entity2.getArchetypeId(&ecs));
    const foobar_row_id = ecs.world.area.entities.getPtr(foobar_entity).entity_row_id;
    try std.testing.expectEqual(0, @intFromEnum(foobar_row_id));
    const foobar2_row_id = ecs.world.area.entities.getPtr(foobar_entity2).entity_row_id;
    try std.testing.expectEqual(1, @intFromEnum(foobar2_row_id));

    const foo_entity = try ecs.createEntity(arena.allocator());
    try foo_entity.addComponent(arena.allocator(), .{ .foo = .{ .foo = 3 } }, &ecs);
    try std.testing.expectEqual(ecs.getArchetypeIdForComponentTags(&.{.foo}).?, foo_entity.getArchetypeId(&ecs));
    const foo_entity_index = ecs.world.area.entities.getPtr(foo_entity);
    try std.testing.expectEqual(0, @intFromEnum(foo_entity_index.entity_row_id));

    const foo1 = foobar_entity.getComponent(.foo, &ecs).?.foo.foo;
    try std.testing.expectEqual(1, foo1);
    const foo2 = foobar_entity2.getComponent(.foo, &ecs).?.foo.foo;
    try std.testing.expectEqual(2, foo2);
    const foo3 = foo_entity.getComponent(.foo, &ecs).?.foo.foo;
    try std.testing.expectEqual(3, foo3);
}

var mutex: std.Thread.Mutex = .{};

pub fn createFooBarEntity(allocator: std.mem.Allocator, ecs: *Ecs) !void {
    mutex.lock();
    defer mutex.unlock();
    var entity = try ecs.createEntity(allocator);
    try entity.addComponents(allocator, &.{
        .{ .foo = .{ .foo = 123 } },
        .{ .bar = .{ .bar = 123, .bar2 = true } },
        .{ .baz = .{ .baz = "hello" } },
    }, ecs);
    try entity.removeComponent(allocator, .baz, ecs);
}

test "multithreaded" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var ecs = try Ecs.init(arena.allocator());
    defer ecs.deinit(arena.allocator());

    var threads = std.ArrayListUnmanaged(std.Thread){};
    var i: usize = 0;
    while (i < 64) : (i += 1) {
        try threads.append(
            arena.allocator(),
            try std.Thread.spawn(.{}, createFooBarEntity, .{ arena.allocator(), &ecs }),
        );
    }
    for (threads.items) |thread| {
        thread.join();
    }
    const archetypeId = ecs.getArchetypeIdForComponentTags(&.{ .foo, .bar }).?;
    const column_id = ecs.component_archetype_index.get(archetypeId, .foo).component_column_id;
    try std.testing.expectEqual(
        64,
        ecs.world.area.components.getPtr(archetypeId).?.columns.items[@intFromEnum(column_id)].rows.items.len,
    );
}
