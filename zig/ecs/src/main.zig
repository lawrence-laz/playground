const std = @import("std");
const builtin = @import("builtin");
const MultiTagArrayList = @import("multi_tag_array_list.zig").MultiTagArrayList;

const Ecs = struct {
    archetypes: Archetypes,
    entities: EntityArchetypeIndexTable,
    systems: Systems,

    pub fn init(ecs: *Ecs, allocator: std.mem.Allocator) !void {
        ecs.* = .{
            .archetypes = try Archetypes.init(allocator),
            .entities = EntityArchetypeIndexTable.init(),
            .systems = undefined,
        };
        try Systems.init(&ecs.*.systems, allocator, ecs);
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.archetypes.deinit(allocator);
        self.entities.rows.deinit(allocator);
        self.systems.deinit(allocator);
    }

    pub fn handleError(self: *@This(), err: anytype) void {
        _ = self;
        std.log.err("Got error: {}", .{err});
        @panic("whoops");
    }
};

const ecs_utils = struct {
    pub fn createEntityId() EntityId {
        return EntityId.new();
    }

    pub fn createEntityNow(allocator: std.mem.Allocator, id: EntityId, ecs: *Ecs) !void {
        try ecs.entities.rows.put(allocator, id, .{
            .archetype_id = Archetypes.empty_id,
            .entity_row_id = @enumFromInt(0), // Identity archetype has no rows.
        });
        try addComponentsNow(allocator, id, &.{.{ .id = id }}, ecs);
    }

    pub fn addComponentsNow(
        allocator: std.mem.Allocator,
        entity_id: EntityId,
        components: []const Component,
        ecs: *Ecs,
    ) !void {
        const entity = ecs.entities.getPtr(entity_id);
        const current_archetype = ecs.archetypes.getPtr(entity.archetype_id);

        for (components) |component| if (current_archetype.component_tags.contains(component)) @panic("how should existing duplicate components be handled?");

        // Change archetype.
        const prev_archetype_id = entity.archetype_id;
        const new_archetype = blk: {
            var archetype = current_archetype;
            for (components) |component| {
                const id = try archetype.getOrCreateSuperArchetypeId(allocator, component, ecs);
                archetype = ecs.archetypes.getPtr(id);
            }
            break :blk archetype;
        };
        entity.archetype_id = new_archetype.id;

        // Assume last row id in the new archetype table.
        const prev_entity_row_id = entity.entity_row_id;
        entity.entity_row_id = @enumFromInt(new_archetype.entityCount());

        const prev_archetype = ecs.archetypes.getPtr(prev_archetype_id);
        const prev_archetype_entity_count = prev_archetype.entityCount();

        if (prev_archetype_entity_count > 0) {
            // Replace last row's id in the prev archetype, since it will be swap-removed.
            const last_entity_row_id = prev_archetype_entity_count - 1;
            // TODO: This is not trivial to get, because usually you don't care about table order. Is swapRemove the correct thing, here?
            // maybe there could be "vacant" bit?
            for (ecs.entities.rows.values()) |*value| {
                if (value.entity_row_id == @as(EntityRowId, @enumFromInt(last_entity_row_id)) and value.archetype_id == prev_archetype_id) {
                    value.entity_row_id = prev_entity_row_id;
                    break;
                }
            }
        } else {
            // Archetype contained a single row only and it was removed, there is nothing to update.
        }

        // Move component data from prev archetype table to the new one.
        var prev_archetype_tags_iter = prev_archetype.component_tags.iterator();
        while (prev_archetype_tags_iter.next()) |prev_tag| {
            switch (prev_tag) {
                inline else => |tag| {
                    const removed_component = prev_archetype.components.getPtr(tag).swapRemove(@intFromEnum(prev_entity_row_id));
                    try new_archetype.components.getPtr(tag).append(allocator, removed_component);
                },
            }
        }

        // Add the new components
        for (components) |component| {
            switch (component) {
                inline else => |payload, tag| {
                    try new_archetype.components.getPtr(tag).append(allocator, payload);
                },
            }
        }
    }

    pub fn removeComponentNow(
        allocator: std.mem.Allocator,
        entity_id: EntityId,
        component_tag_to_remove: ComponentTag,
        ecs: *Ecs,
    ) !void {
        const entity = ecs.entities.getPtr(entity_id);
        const archetype = ecs.archetypes.getPtr(entity.archetype_id);
        if (!archetype.component_tags.contains(component_tag_to_remove)) {
            return;
        }

        // Change archetype.
        const prev_archetype = archetype;
        const new_archetype_id = try prev_archetype.getOrCreateSubArchetypeId(allocator, component_tag_to_remove, ecs);
        const new_archetype = ecs.archetypes.getPtr(new_archetype_id);
        entity.archetype_id = new_archetype_id;

        // Assume last row id in the new archetype table.
        const prev_entity_row_id = entity.entity_row_id;
        entity.entity_row_id = @enumFromInt(new_archetype.entityCount());

        // Replace last row's id in the prev archetype, since it will be swap removed.
        const last_entity_row_id = prev_archetype.entityCount() - 1;
        for (ecs.entities.rows.values()) |*other_entity| {
            if (other_entity.entity_row_id == @as(EntityRowId, @enumFromInt(last_entity_row_id))) {
                other_entity.entity_row_id = prev_entity_row_id;
                break;
            }
        }

        // Move component data from prev archetype table to the new one.
        var prev_archetype_tags_iter = prev_archetype.component_tags.iterator();
        while (prev_archetype_tags_iter.next()) |prev_tag| {
            switch (prev_tag) {
                inline else => |tag| {
                    const removed_component = prev_archetype.components.getPtr(tag).swapRemove(@intFromEnum(prev_entity_row_id));
                    if (tag == component_tag_to_remove) {
                        // The removed component is not added to the new table.
                        continue;
                    }
                    try new_archetype.components.getPtr(tag).append(allocator, removed_component);
                },
            }
        }
    }

    pub fn getComponent(entity_id: EntityId, comptime component_tag: ComponentTag, ecs: *const Ecs) ?std.meta.FieldType(Component, component_tag) {
        const entity = ecs.entities.getPtr(entity_id);
        const component_rows = ecs.archetypes.getPtr(entity.archetype_id).components.getPtr(component_tag).items;
        return if (component_rows.len > @intFromEnum(entity.entity_row_id))
            component_rows[@intFromEnum(entity.entity_row_id)]
        else
            null; // Entity's archetype does not contain the requested component.
    }

    pub fn getEntityComponentTags(entity_id: EntityId, ecs: *const Ecs) std.EnumSet(ComponentTag) {
        const entity = ecs.entities.getPtr(entity_id);
        const archetype = ecs.archetypes.getPtr(entity.archetype_id);
        return archetype.component_tags;
    }

    pub fn getArchetypeId(self: EntityId, ecs: *const Ecs) ArchetypeId {
        return ecs.entities.getPtr(self).archetype_id;
    }

    pub fn getArchetypeIdByComponentTags(ecs: *const Ecs, component_tags: []const ComponentTag) ?ArchetypeId {
        var component_tags_set = std.EnumSet(ComponentTag).initMany(component_tags);
        component_tags_set.setPresent(.id, true);
        return ecs.archetypes.getIdByComponentTags(component_tags_set);
    }
};

const Systems = struct {
    ecs: *Ecs,
    thread_pool: std.Thread.Pool,
    contexts: struct {
        worker_1: SystemContext,
        worker_2: SystemContext,
    },
    iters: struct {
        foo: foo_system.Iter,
        bar: bar_system.Iter,
        foo_bar: foo_bar_system.Iter,
        invoice_calc: invoice_calc_system.Iter,
        counter: counter_system.Iter,
    },
    iter_cache_id: usize,

    pub fn init(system_runner: *Systems, allocator: std.mem.Allocator, ecs: *Ecs) !void {
        system_runner.ecs = ecs;
        try std.Thread.Pool.init(&system_runner.*.thread_pool, .{ .allocator = allocator });
        system_runner.contexts = .{
            .worker_1 = SystemContext.init(ecs),
            .worker_2 = SystemContext.init(ecs),
        };
        system_runner.iters = .{
            .foo = foo_system.Iter.init(ecs),
            .bar = bar_system.Iter.init(ecs),
            .foo_bar = foo_bar_system.Iter.init(ecs),
            .invoice_calc = invoice_calc_system.Iter.init(ecs),
            .counter = counter_system.Iter.init(ecs),
        };
        system_runner.iter_cache_id = 0;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.thread_pool.deinit();

        self.contexts.worker_1.deinit(allocator);
        self.contexts.worker_2.deinit(allocator);

        self.iters.foo.deinit(allocator);
        self.iters.bar.deinit(allocator);
        self.iters.foo_bar.deinit(allocator);
        self.iters.invoice_calc.deinit(allocator);
        self.iters.counter.deinit(allocator);
    }

    // TODO: Make it so that `tick()` does not allocate?
    pub fn tick(self: *@This(), allocator: std.mem.Allocator) !void {
        try self.refreshIters(allocator);

        {
            var wait: std.Thread.WaitGroup = .{};
            self.thread_pool.spawnWg(&wait, foo_system.tick, .{ allocator, &self.iters.foo, &self.contexts.worker_1 });
            self.thread_pool.spawnWg(&wait, bar_system.tick, .{ &self.iters.bar, &self.contexts.worker_1 });
            wait.wait();
        }
        try foo_bar_system.tick(&self.iters.foo_bar, &self.contexts.worker_1);
        invoice_calc_system.tick(&self.iters.invoice_calc, &self.contexts.worker_1);
        counter_system.tick(&self.iters.counter);
        try entity_operations_system.tick(allocator, &self.contexts.worker_1);
    }

    fn refreshIters(self: *@This(), allocator: std.mem.Allocator) !void {
        std.debug.assert(self.iter_cache_id <= self.ecs.archetypes.count()); // Archetypes are never deleted, so cache id is monotonically increasing.

        if (self.iter_cache_id == self.ecs.archetypes.count()) {
            // Iters are up to date, no new archetypes were created since last refresh.
            return;
        }

        // New archetypes created since last cache refresh.
        self.iter_cache_id = self.ecs.archetypes.count();
        var iters = &self.iters;
        const Iters = @TypeOf(self.iters);
        inline for (std.meta.fields(Iters)) |iter_field| {
            var iter = &@field(iters, iter_field.name);
            try iter.refreshTables(allocator);
        }
    }
};

const SystemContext = struct {
    entity_operations: std.ArrayListUnmanaged(EntityOperation),
    ecs: *Ecs,

    pub fn init(ecs: *Ecs) SystemContext {
        return .{ .entity_operations = .{}, .ecs = ecs };
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.entity_operations.deinit(allocator);
    }

    pub fn createEntity(self: *@This(), allocator: std.mem.Allocator) EntityId {
        const entity_id: EntityId = ecs_utils.createEntityId();
        self.entity_operations.append(
            allocator,
            .{ .create_entity = .{ .entity_id = entity_id } },
        ) catch |err| switch (err) {
            error.OutOfMemory => self.ecs.handleError(err),
        };
        return entity_id;
    }

    pub fn deleteEntity(self: *@This(), allocator: std.mem.Allocator, entity_id: EntityId) void {
        self.entity_operations.append(
            allocator,
            .{ .delete_entity = .{ .entity_id = entity_id } },
        ) catch |err| switch (err) {
            error.OutOfMemory => self.ecs.handleError(err),
        };
    }

    pub fn addComponent(self: *@This(), allocator: std.mem.Allocator, entity_id: EntityId, component: Component) void {
        self.entity_operations.append(
            allocator,
            .{ .add_component = .{ .entity_id = entity_id, .component = component } },
        ) catch |err| switch (err) {
            error.OutOfMemory => self.ecs.handleError(err),
        };
    }

    pub fn removeComponent(self: *@This(), allocator: std.mem.Allocator, entity_id: EntityId, component_tag: ComponentTag) void {
        self.entity_operations.append(
            allocator,
            .{ .remove_component = .{ .entity_id = entity_id, .component_tag = component_tag } },
        ) catch |err| switch (err) {
            error.OutOfMemory => self.ecs.handleError(err),
        };
    }
};

const entity_operations_system = struct {
    pub fn tick(allocator: std.mem.Allocator, context: *SystemContext) !void {
        inline for (std.meta.fields(@TypeOf(context.ecs.systems.contexts))) |context_field| {
            const entity_operations: *std.ArrayListUnmanaged(EntityOperation) = &@field(context.ecs.systems.contexts, context_field.name).entity_operations;
            for (entity_operations.items) |operation| switch (operation) {
                .create_entity => |req| try ecs_utils.createEntityNow(allocator, req.entity_id, context.ecs),
                .delete_entity => @panic("TODO"),
                .add_component => |req| try ecs_utils.addComponentsNow(allocator, req.entity_id, &.{req.component}, context.ecs),
                .add_many_components => @panic("TODO: this provides an iter, we need slice, once use case is here - figure it out"),
                .remove_component => |req| try ecs_utils.removeComponentNow(allocator, req.entity_id, req.component_tag, context.ecs),
            };
            entity_operations.clearRetainingCapacity();
        }
    }
};

const counter_system = struct {
    const Iter = EntityIter(struct {
        marked: *void,
        counter: *i32,
    });

    pub fn tick(iter: *Iter) void {
        while (iter.next()) |entity| {
            entity.counter.* += 1;
        }
    }
};
test counter_system {
    var ecs: Ecs = undefined;
    try Ecs.init(&ecs, std.testing.allocator);
    defer ecs.deinit(std.testing.allocator);

    const marked_entity = ecs_utils.createEntityId();
    const unmarked_entity = ecs_utils.createEntityId();

    try ecs_utils.createEntityNow(std.testing.allocator, marked_entity, &ecs);
    try ecs_utils.addComponentsNow(std.testing.allocator, marked_entity, &.{ .{ .counter = 0 }, .{ .marked = {} } }, &ecs);

    try ecs_utils.createEntityNow(std.testing.allocator, unmarked_entity, &ecs);
    try ecs_utils.addComponentsNow(std.testing.allocator, unmarked_entity, &.{.{ .counter = 0 }}, &ecs);

    try ecs.systems.tick(std.testing.allocator);

    const marked_counter = ecs_utils.getComponent(marked_entity, .counter, &ecs).?;
    const unmarked_counter = ecs_utils.getComponent(unmarked_entity, .counter, &ecs).?;

    try std.testing.expectEqual(1, marked_counter);
    try std.testing.expectEqual(0, unmarked_counter);
}

const foo_system = struct {
    const Iter = EntityIter(struct {
        id: *const EntityId,
        foo: *Foo,
    });

    pub fn tick(allocator: std.mem.Allocator, iter: *Iter, context: *SystemContext) void {
        while (iter.next()) |entity| {
            if (entity.foo.foo >= 50) {
                context.removeComponent(allocator, entity.id.*, .foo);
            } else {
                entity.foo.foo += 1;
            }
        }
    }
};

const invoice_calc_system = struct {
    const Iter = EntityIter(struct {
        invoice: *Invoice,
        discount: ?*const Discount,
    });

    pub fn tick(iter: *Iter, context: *SystemContext) void {
        _ = context;
        while (iter.next()) |entity| {
            if (entity.discount) |discount| {
                const amount = 100 * (1 - discount.percent);
                entity.invoice.sum += @intFromFloat(@floor(amount));
            } else {
                entity.invoice.sum += 100;
            }
        }
    }
};

test invoice_calc_system {
    var ecs: Ecs = undefined;
    try Ecs.init(&ecs, std.testing.allocator);
    defer ecs.deinit(std.testing.allocator);

    const no_discount_entity = ecs_utils.createEntityId();
    const discount_entity = ecs_utils.createEntityId();

    try ecs_utils.createEntityNow(std.testing.allocator, no_discount_entity, &ecs);
    try ecs_utils.addComponentsNow(std.testing.allocator, no_discount_entity, &.{.{ .invoice = .{ .sum = 0 } }}, &ecs);

    try ecs_utils.createEntityNow(std.testing.allocator, discount_entity, &ecs);
    try ecs_utils.addComponentsNow(std.testing.allocator, discount_entity, &.{ .{ .invoice = .{ .sum = 0 } }, .{ .discount = .{ .percent = 0.2 } } }, &ecs);

    try ecs.systems.tick(std.testing.allocator);

    const no_discount_invoice = ecs_utils.getComponent(no_discount_entity, .invoice, &ecs).?;
    const discount_invoice = ecs_utils.getComponent(discount_entity, .invoice, &ecs).?;

    try std.testing.expectEqual(80, discount_invoice.sum);
    try std.testing.expectEqual(100, no_discount_invoice.sum);
}

const bar_system = struct {
    const Iter = EntityIter(struct {
        id: *const EntityId,
        bar: *Bar,
    });

    pub fn tick(iter: *Iter, context: *SystemContext) void {
        _ = context;
        while (iter.next()) |entity| {
            entity.bar.bar += 1;
            std.log.debug("    bar_system: ID:{}, bar:{d}", .{ entity.id, entity.bar.bar });
        }
    }
};

const foo_bar_system = struct {
    const Iter = EntityIter(struct {
        id: *const EntityId,
        foo: *Foo,
        bar: *Bar,
    });

    pub fn tick(iter: *Iter, context: *SystemContext) !void {
        // _ = context;
        while (iter.next()) |entity| {
            entity.foo.foo += 1;
            entity.bar.bar += 1;
            std.log.debug("foo_bar_system: ID:{}, bar:{d}", .{ entity.id, entity.bar.bar });
            const from_utils = ecs_utils.getComponent(entity.id.*, .bar, context.ecs).?;
            std.log.debug("from getComponent: ID:{}, bar:{d}", .{ entity.id, from_utils.bar });
        }
    }
};

fn EntityIterTable(EntityView: type) type {
    return struct {
        archetype_id: ArchetypeId,
        columns: EntityIterColumns(EntityView),

        pub fn getRowCount(self: *const @This()) usize {
            const first_field = std.meta.fields(@TypeOf(self.columns))[0];
            return if (@field(self.columns, first_field.name)) |rows| return rows.items.len else return 0;
        }
    };
}

fn EntityIterColumns(EntityView: type) type {
    const column_count = std.meta.fields(EntityView).len;
    var fields: [column_count]std.builtin.Type.StructField = undefined;
    inline for (std.meta.fields(EntityView), 0..) |field, i| {
        const ItemType = switch (@typeInfo(field.type)) {
            .Pointer => |ptr_info| ptr_info.child,
            .Optional => |optional_info| switch (@typeInfo(optional_info.child)) {
                .Pointer => |ptr_info| ptr_info.child,
                else => @compileError("Entity view field '" ++ field.name ++ "' has unsupported type '" ++ @typeName(field.type) ++ "'"),
            },
            else => @compileError("Entity view field '" ++ field.name ++ "' has unsupported type '" ++ @typeName(field.type) ++ "'"),
        };
        const undefined_value: ?*std.ArrayListUnmanaged(ItemType) = undefined;
        fields[i] = std.builtin.Type.StructField{
            .name = field.name,
            .type = ?*std.ArrayListUnmanaged(ItemType),
            .default_value = @ptrCast(&undefined_value),
            .is_comptime = false,
            .alignment = @alignOf(?*std.ArrayListUnmanaged(ItemType)),
        };
    }
    return @Type(std.builtin.Type{
        .Struct = .{
            .fields = &fields,
            .decls = &.{},
            .layout = .auto,
            .is_tuple = false,
        },
    });
}

fn EntityIter(EntityViewRow: type) type {
    return struct {
        ecs: *const Ecs,
        tables: std.ArrayListUnmanaged(EntityIterTable(EntityViewRow)),
        table_id: usize = 0,
        row_id: usize = 0,
        cache_id: usize = 0, // When does not equal to ecs.archetypes.len, need to update tables.

        pub fn init(ecs: *const Ecs) EntityIter(EntityViewRow) {
            return .{ .ecs = ecs, .tables = .{} };
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            self.tables.deinit(allocator);
        }

        pub fn reset(self: *@This(), allocator: std.mem.Allocator) void {
            if (self.cache_id < self.ecs.archetypes.count()) {
                self.refreshTables(allocator);
            }
            self.table_id = 0;
            self.row_id = 0;
        }

        pub fn next(self: *@This()) ?EntityViewRow {
            table: while (self.table_id < self.tables.items.len) {
                while (self.row_id < self.tables.items[self.table_id].getRowCount()) {
                    const table = self.tables.items[self.table_id];
                    const row_fields = std.meta.fields(EntityViewRow);
                    var row: EntityViewRow = undefined;
                    inline for (row_fields) |row_field| {
                        const maybe_col = @field(table.columns, row_field.name);
                        if (maybe_col != null) {
                            const col = maybe_col.?;
                            @field(row, row_field.name) = &col.items[self.row_id];
                        } else {
                            if (@typeInfo(row_field.type) == .Optional) {
                                @field(row, row_field.name) = null;
                            } else {
                                unreachable; // Only optional types can have column be null as checked in refreshTables funciton.
                            }
                        }
                    }
                    self.row_id += 1;
                    return row;
                } else {
                    // Done with current table
                    self.table_id += 1;
                    self.row_id = 0;
                    continue :table;
                }
            } else {
                // Done with all tables
                self.row_id = 0;
                self.table_id = 0;
                return null;
            }
        }

        fn refreshTables(self: *@This(), allocator: std.mem.Allocator) !void {
            const view_cols = getEntityViewCols();
            archetypes: for (self.ecs.archetypes.values()[self.cache_id..]) |*archetype| {
                for (view_cols) |view_col| {
                    if (!view_col.is_optional and !archetype.component_tags.contains(view_col.component_tag)) {
                        // Skipping an achetype that does not contain a required (is_optional=false) component.
                        continue :archetypes;
                    }
                }
                var columns: EntityIterColumns(EntityViewRow) = .{};
                inline for (std.meta.fields(EntityViewRow)) |field| {
                    const component_tag = comptime std.meta.stringToEnum(ComponentTag, field.name) orelse @compileError("Field name does not match ComponentTag");
                    if (archetype.component_tags.contains(component_tag)) {
                        @field(columns, field.name) = archetype.components.getPtr(component_tag);
                    } else {
                        std.debug.assert(@typeInfo(field.type) == .Optional); // Only optional fields can have column collection null.
                        @field(columns, field.name) = null; // This archetype does not contain the requested component, but the component is optional.
                    }
                }
                try self.tables.append(allocator, .{
                    .archetype_id = archetype.id,
                    .columns = columns,
                });
            }
            self.cache_id = self.ecs.archetypes.count();
        }

        const EntityViewCol = struct {
            component_tag: ComponentTag,
            is_optional: bool,
        };
        fn getEntityViewCols() [std.meta.fields(EntityViewRow).len]EntityViewCol {
            var cols: [std.meta.fields(EntityViewRow).len]EntityViewCol = undefined;
            inline for (std.meta.fields(EntityViewRow), 0..) |field, i| {
                const component_tag = std.meta.stringToEnum(ComponentTag, field.name) orelse @panic("Field name does not match ComponentTag");
                const is_optional = std.meta.activeTag(@typeInfo(field.type)) == .Optional;
                cols[i] = .{ .component_tag = component_tag, .is_optional = is_optional };
            }
            return cols;
        }
    };
}

const Archetypes = struct {
    pub const empty_id: ArchetypeId = @enumFromInt(0);

    rows: std.AutoArrayHashMapUnmanaged(ArchetypeId, Archetype),
    component_tags_index: std.AutoHashMapUnmanaged(std.EnumSet(ComponentTag), ArchetypeId),

    pub fn init(allocator: std.mem.Allocator) !Archetypes {
        var archetypes: Archetypes = .{
            .rows = .{},
            .component_tags_index = .{},
        };
        const empty_archetype = Archetype.init(@enumFromInt(archetypes.rows.count()), std.EnumSet(ComponentTag).initEmpty());
        try archetypes.put(allocator, empty_id, empty_archetype);
        return archetypes;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        for (self.rows.values()) |*value| {
            value.deinit(allocator);
        }
        self.rows.deinit(allocator);
        self.component_tags_index.deinit(allocator);
    }

    pub fn put(self: *@This(), allocator: std.mem.Allocator, id: ArchetypeId, archetype: Archetype) !void {
        try self.rows.put(allocator, id, archetype);
        errdefer _ = self.rows.swapRemove(id);
        try self.component_tags_index.put(allocator, archetype.component_tags, id);
    }

    pub fn count(self: *const @This()) usize {
        return self.rows.count();
    }

    pub fn values(self: *const @This()) []Archetype {
        return self.rows.values();
    }

    pub fn getPtr(self: *const @This(), id: ArchetypeId) *Archetype {
        return self.rows.getPtr(id).?;
    }

    pub fn get(self: *const @This(), id: ArchetypeId) Archetype {
        return self.rows.get(id);
    }

    pub fn getIdByComponentTags(self: *const @This(), component_tags: std.EnumSet(ComponentTag)) ?ArchetypeId {
        return self.component_tags_index.get(component_tags);
    }

    pub fn getOrCreatePtrByComponentTags(self: *@This(), allocator: std.mem.Allocator, component_tags: std.EnumSet(ComponentTag)) !*Archetype {
        if (self.component_tags_index.get(component_tags)) |existing_archetype_id| {
            return self.getPtr(existing_archetype_id);
        } else {
            const new_archetype = Archetype.init(@enumFromInt(self.rows.count()), component_tags);
            try self.put(allocator, new_archetype.id, new_archetype);
            return self.rows.getPtr(new_archetype.id).?;
        }
    }
};

const ArchetypeId = enum(usize) {
    _,
    pub fn jsonStringify(value: @This(), jws: anytype) !void {
        try jws.write(@intFromEnum(value));
    }
};

/// Archetype represents a class of entities as defined by the components it owns.
/// When an entity changes the components it has it is moved into another archetype.
const Archetype = struct {
    id: ArchetypeId,
    components: MultiTagArrayList(Component), // TODO: Rename from cols? what's better though?
    component_tags: std.EnumSet(ComponentTag),
    super_archetypes: std.AutoHashMapUnmanaged(ComponentTag, ArchetypeId),
    sub_archetypes: std.AutoHashMapUnmanaged(ComponentTag, ArchetypeId),

    pub fn init(id: ArchetypeId, component_tags: std.EnumSet(ComponentTag)) Archetype {
        return .{
            .id = id,
            .components = MultiTagArrayList(Component).init(),
            .component_tags = component_tags,
            .super_archetypes = .{},
            .sub_archetypes = .{},
        };
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.components.deinit(allocator);
        self.super_archetypes.deinit(allocator);
        self.sub_archetypes.deinit(allocator);
    }

    pub fn entityCount(self: *const @This()) usize {
        var tag_iter = self.component_tags.iterator();
        if (tag_iter.next()) |first_tag| {
            const first_component_count = self.components.count(first_tag);

            if (builtin.mode == .Debug) {
                var tags = self.component_tags.iterator();
                while (tags.next()) |tag| {
                    std.debug.assert(self.components.count(tag) == first_component_count); // All components should have the same amount of items.
                }
            }

            return first_component_count;
        } else {
            // This is identity archetype without any components.
            // Returning 0 entities for this archetype because cannot determine entity count by looking at empty tables.
            // If there's ever a need to get actual empty entity count, then this would have to look into entity index.
            return 0;
        }
    }

    pub fn getOrCreateSuperArchetypeId(
        self: *@This(),
        allocator: std.mem.Allocator,
        component_tag_to_add: ComponentTag,
        ecs: *Ecs,
    ) !ArchetypeId {
        std.debug.assert(!self.component_tags.contains(component_tag_to_add));

        if (self.super_archetypes.get(component_tag_to_add)) |super_archetype_id| {
            // Link already exists
            return super_archetype_id;
        }

        // Create
        var new_component_tags = self.component_tags;
        new_component_tags.insert(component_tag_to_add);
        var super_archetype = try ecs.archetypes.getOrCreatePtrByComponentTags(allocator, new_component_tags);

        // Add back link to this
        try super_archetype.sub_archetypes.put(allocator, component_tag_to_add, self.id);

        // Add link to new
        try self.super_archetypes.put(allocator, component_tag_to_add, super_archetype.id);

        return super_archetype.id;
    }

    pub fn getOrCreateSubArchetypeId(
        self: *@This(),
        allocator: std.mem.Allocator,
        component_tag_to_remove: ComponentTag,
        ecs: *Ecs,
    ) !ArchetypeId {
        std.debug.assert(self.component_tags.contains(component_tag_to_remove));

        if (self.sub_archetypes.get(component_tag_to_remove)) |sub_archetype_id| {
            // Link already exists
            return sub_archetype_id;
        }

        // Create
        var new_component_tags = self.component_tags;
        new_component_tags.remove(component_tag_to_remove);
        var sub_archetype = try ecs.archetypes.getOrCreatePtrByComponentTags(allocator, new_component_tags);

        // Add back link to this
        try sub_archetype.super_archetypes.put(allocator, component_tag_to_remove, self.id);

        // Add link to new
        try self.sub_archetypes.put(allocator, component_tag_to_remove, sub_archetype.id);

        return sub_archetype.id;
    }
};

const EntityOperation = union(enum) {
    create_entity: struct { entity_id: EntityId },
    delete_entity: struct { entity_id: EntityId },
    add_component: struct { entity_id: EntityId, component: Component },
    add_many_components: struct { entity_id: EntityId, components: std.EnumArray(ComponentTag, Component) },
    remove_component: struct { entity_id: EntityId, component_tag: ComponentTag },
};

const ComponentTag = enum(usize) { id, foo, bar, baz, invoice, discount, counter, marked };
const Component = union(ComponentTag) {
    id: EntityId,
    foo: Foo,
    bar: Bar,
    baz: Baz,
    invoice: Invoice,
    discount: Discount,
    counter: i32,
    marked: void,

    const count = @typeInfo(ComponentTag).Enum.fields.len;
};
const Foo = struct { foo: i32 };
const Bar = struct { bar: i32, bar2: bool };
const Baz = struct { baz: []const u8 };
const Invoice = struct { sum: i32 };
const Discount = struct { percent: f32 };

const EntityArchetypeIndexTable = struct {
    rows: std.AutoArrayHashMapUnmanaged(EntityId, EntityArchetypeIndexRow),

    pub fn init() EntityArchetypeIndexTable {
        return .{ .rows = .{} };
    }

    pub fn getPtr(self: @This(), entity_id: EntityId) *EntityArchetypeIndexRow {
        return self.rows.getPtr(entity_id).?;
    }

    pub fn get(self: @This(), entity_id: EntityId) *EntityArchetypeIndexRow {
        return self.rows.get(entity_id).?;
    }
};

const EntityId = @import("ulid.zig").Ulid;

const EntityArchetypeIndexRow = struct {
    archetype_id: ArchetypeId,
    entity_row_id: EntityRowId,
};

/// Entity's row id in archetype table.
/// This changes when an entity is moved from one archetype into another.
const EntityRowId = enum(usize) {
    _,

    pub fn jsonStringify(value: @This(), jws: anytype) !void {
        try jws.write(@intFromEnum(value));
    }
};

test "archetypes of components of entities" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var ecs: Ecs = undefined;
    try Ecs.init(&ecs, arena.allocator());
    defer ecs.deinit(arena.allocator());

    const foobar_entity = ecs_utils.createEntityId();
    try ecs_utils.createEntityNow(arena.allocator(), foobar_entity, &ecs);
    try ecs_utils.addComponentsNow(arena.allocator(), foobar_entity, &.{
        .{ .foo = .{ .foo = 1 } },
        .{ .bar = .{ .bar = 456, .bar2 = true } },
    }, &ecs);

    // Adding and removing some component.
    try ecs_utils.addComponentsNow(arena.allocator(), foobar_entity, &.{.{ .baz = .{ .baz = "woo" } }}, &ecs);
    try ecs_utils.removeComponentNow(arena.allocator(), foobar_entity, .baz, &ecs);

    const foobar_entity2 = ecs_utils.createEntityId();
    try ecs_utils.createEntityNow(arena.allocator(), foobar_entity2, &ecs);
    try ecs_utils.addComponentsNow(arena.allocator(), foobar_entity2, &.{
        .{ .foo = .{ .foo = 2 } },
        .{ .bar = .{ .bar = 456, .bar2 = true } },
    }, &ecs);

    try std.testing.expect(!foobar_entity.equals(foobar_entity2));

    try std.testing.expectEqual(ecs_utils.getArchetypeId(foobar_entity, &ecs), ecs_utils.getArchetypeId(foobar_entity2, &ecs));
    const foobar_row_id = ecs.entities.getPtr(foobar_entity).entity_row_id;
    try std.testing.expectEqual(0, @intFromEnum(foobar_row_id));
    const foobar2_row_id = ecs.entities.getPtr(foobar_entity2).entity_row_id;
    try std.testing.expectEqual(1, @intFromEnum(foobar2_row_id));

    const foo_entity = ecs_utils.createEntityId();
    try ecs_utils.createEntityNow(arena.allocator(), foo_entity, &ecs);
    try ecs_utils.addComponentsNow(arena.allocator(), foo_entity, &.{.{ .foo = .{ .foo = 3 } }}, &ecs);
    try std.testing.expectEqual(ecs_utils.getArchetypeIdByComponentTags(&ecs, &.{.foo}).?, ecs_utils.getArchetypeId(foo_entity, &ecs));
    const foo_entity_index = ecs.entities.getPtr(foo_entity);
    try std.testing.expectEqual(0, @intFromEnum(foo_entity_index.entity_row_id));

    const foo1 = ecs_utils.getComponent(foobar_entity, .foo, &ecs).?.foo;
    try std.testing.expectEqual(1, foo1);
    const foo2 = ecs_utils.getComponent(foobar_entity2, .foo, &ecs).?.foo;
    try std.testing.expectEqual(2, foo2);
    const foo3 = ecs_utils.getComponent(foo_entity, .foo, &ecs).?.foo;
    try std.testing.expectEqual(3, foo3);
}

test "run systems" {
    var ecs: Ecs = undefined;
    try Ecs.init(&ecs, std.testing.allocator);
    defer ecs.deinit(std.testing.allocator);

    // Create entities and components
    const foo_id = EntityId.new();
    try ecs_utils.createEntityNow(std.testing.allocator, foo_id, &ecs);
    try ecs_utils.addComponentsNow(std.testing.allocator, foo_id, &.{
        .{ .foo = .{ .foo = 0 } },
    }, &ecs);

    const bar_id = EntityId.new();
    try ecs_utils.createEntityNow(std.testing.allocator, bar_id, &ecs);
    try ecs_utils.addComponentsNow(std.testing.allocator, bar_id, &.{
        .{ .bar = .{ .bar = 0, .bar2 = false } },
    }, &ecs);

    const foo_bar_id = EntityId.new();
    try ecs_utils.createEntityNow(std.testing.allocator, foo_bar_id, &ecs);
    try ecs_utils.addComponentsNow(std.testing.allocator, foo_bar_id, &.{
        .{ .bar = .{ .bar = 0, .bar2 = false } },
        .{ .foo = .{ .foo = 0 } },
    }, &ecs);

    // Run systems
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        try ecs.systems.tick(std.testing.allocator);
    }

    // Assert
    try std.testing.expectEqual(null, ecs_utils.getComponent(foo_id, .foo, &ecs));
    try std.testing.expectEqual(100, ecs_utils.getComponent(bar_id, .bar, &ecs).?.bar);
    try std.testing.expectEqual(null, ecs_utils.getComponent(foo_bar_id, .foo, &ecs));
    const foobar = ecs_utils.getComponent(foo_bar_id, .bar, &ecs);
    try std.testing.expectEqual(126, foobar.?.bar);
}
