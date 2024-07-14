const std = @import("std");
const StructField = std.builtin.Type.StructField;
const UnionField = std.builtin.Type.UnionField;

/// Generates a type where each field is std.ArrayList of the given type fields.
pub fn MultiArrayList(comptime T: type) type {
    const given_fields = std.meta.fields(T);
    var new_fields: [given_fields.len]StructField = undefined;
    inline for (given_fields, 0..) |given_field, i| {
        const field_name = given_field.name;
        const FieldType = given_field.type;
        const default_undefined_value: std.ArrayList(FieldType) = undefined;
        new_fields[i] = StructField{
            .name = field_name,
            .type = std.ArrayList(FieldType),
            .default_value = &default_undefined_value,
            .is_comptime = false,
            .alignment = @alignOf(std.ArrayList(FieldType)),
        };
    }
    const type_info: std.builtin.Type = .{
        .Struct = .{
            .layout = .auto,
            .decls = &.{},
            .is_tuple = false,
            .fields = &new_fields,
        },
    };
    return @Type(type_info);
}

/// Generates a type, where each field is a std.ArrayList for all possible union fields.
pub fn SparseUnionMultiArrayList(comptime T: type) type {
    return struct {
        data: MultiArrayList(T),

        pub fn init(allocator: std.mem.Allocator) SparseUnionMultiArrayList(T) {
            var result: SparseUnionMultiArrayList(T) = .{ .data = .{} };

            const t_fields = std.meta.fields(T);
            inline for (t_fields) |field| {
                const union_field = @as(UnionField, field);
                @field(result.data, union_field.name) = std.ArrayList(union_field.type).init(allocator);
            }

            return result;
        }

        pub fn deinit(self: *@This()) void {
            const t_fields = std.meta.fields(T);
            inline for (t_fields) |field| {
                const union_field = @as(UnionField, field);
                @field(self.data, union_field.name).deinit();
            }
        }

        pub fn add(self: *@This(), item: anytype) !void {
            const TComponent = @TypeOf(item);
            const fields = std.meta.fields(MultiArrayList(T));
            inline for (fields) |field| {
                const TArray = field.type;
                const ItemType = std.meta.Child(std.meta.FieldType(TArray, .items));
                if (ItemType == TComponent) {
                    try @field(self.data, field.name).append(item);
                    return;
                }
            } else {
                @compileError("Unsupported component type " ++ @typeName(TComponent));
            }
        }
    };
}

/// Generates an iterator for a specific view from a source type.
/// Filters only those entities (by field .id) that have all components as defined by TView fields.
pub fn Iterator(comptime TView: type, comptime TSource: type) type {
    return struct {
        state: State(),

        pub fn init(source: *SparseUnionMultiArrayList(TSource)) @This() {
            var result = Iterator(TView, TSource){ .state = .{} };
            const view_fields = std.meta.fields(TView);
            inline for (view_fields) |field| {
                @field(result.state, field.name) = @field(source.data, field.name);
            }

            return result;
        }

        /// Gets a type that stores iterator sources and indexes.
        pub fn State() type {
            const given_fields = std.meta.fields(TView);
            var new_fields: [given_fields.len * 2]StructField = undefined;
            inline for (given_fields, 0..) |given_field, i| {
                const field_name = given_field.name;
                const FieldType = std.meta.Child(given_field.type); // View is a pointer
                const default_undefined_value: std.ArrayList(FieldType) = undefined;
                new_fields[i] = StructField{
                    .name = field_name,
                    .type = std.ArrayList(FieldType),
                    .default_value = &default_undefined_value,
                    .is_comptime = false,
                    .alignment = @alignOf(std.ArrayList(FieldType)),
                };
                const default_index: usize = 0;
                new_fields[given_fields.len + i] = StructField{
                    .name = field_name ++ "_index",
                    .type = usize,
                    .default_value = &default_index,
                    .is_comptime = false,
                    .alignment = @alignOf(usize),
                };
            }
            const type_info: std.builtin.Type = .{
                .Struct = .{
                    .layout = .auto,
                    .decls = &.{},
                    .is_tuple = false,
                    .fields = &new_fields,
                },
            };
            return @Type(type_info);
        }

        pub fn next(self: *@This()) ?TView {
            const fields = std.meta.fields(TView);
            var result: TView = .{};
            while (self.hasNext()) {
                const lowest_id = self.getLowestId();
                std.log.debug("lowest_id={d}", .{lowest_id});
                if (self.allFieldsSameId(lowest_id)) {
                    inline for (fields) |field| {
                        @field(result, field.name) = &@field(self.state, field.name).items[@field(self.state, field.name ++ "_index")];
                        @field(self.state, field.name ++ "_index") += 1;
                        std.log.debug("{s} += 1   =>   {d}", .{ field.name ++ "_index", @field(self.state, field.name ++ "_index") });
                    }
                    std.log.debug("Found match: id={d}", .{lowest_id});
                    return result;
                } else {
                    self.incrementIndexes(lowest_id);
                }
            }
            return null;
        }

        inline fn hasNext(self: *@This()) bool {
            const fields = std.meta.fields(TView);
            inline for (fields) |field| {
                const index = @field(self.state, field.name ++ "_index");
                const len = @field(self.state, field.name).items.len;
                if (index >= len) {
                    std.log.debug("hasNext() == false : {s} field index {d} >= len {d}", .{ field.name, index, len });
                    return false;
                }
            }
            return true;
        }

        inline fn getLowestId(self: *@This()) u32 {
            const fields = std.meta.fields(TView);
            const first_field_name = fields[0].name;
            var id: u32 = @field(self.state, first_field_name).items[@field(self.state, first_field_name ++ "_index")].id;
            inline for (fields) |field| {
                id = @min(id, @field(self.state, field.name).items[@field(self.state, field.name ++ "_index")].id);
            }
            return id;
        }

        inline fn allFieldsSameId(self: *@This(), id: u32) bool {
            const fields = std.meta.fields(TView);
            inline for (fields) |field| {
                const index = @field(self.state, field.name ++ "_index");
                const id_at_index = @field(self.state, field.name).items[index].id;
                if (id != id_at_index) {
                    std.log.debug("{d} != {s}[{d}]={d}", .{ id, field.name, index, id_at_index });
                    return false;
                }
            }
            return true;
        }

        inline fn incrementIndexes(self: *@This(), id: u32) void {
            const fields = std.meta.fields(TView);
            inline for (fields) |field| {
                const index = @field(self.state, field.name ++ "_index");
                if (id == @field(self.state, field.name).items[index].id) {
                    @field(self.state, field.name ++ "_index") += 1;
                    std.log.debug("{s} += 1   =>   {d}", .{ field.name ++ "_index", @field(self.state, field.name ++ "_index") });
                }
            }
        }
    };
}

const Position = struct {
    id: u32 = 0,
    x: f32 = 0,
    y: f32 = 0,
};

const Movement = struct {
    id: u32 = 0,
    dir_x: f32 = 0,
    dir_y: f32 = 0,
    speed: f32 = 0,
};

const Health = struct {
    id: u32 = 0,
    points: u32 = 0,
};

const Component = union(enum) {
    position: Position,
    movement: Movement,
    health: Health,
};

const MovementSystem = struct {
    const State = struct { position: *Position = undefined, movement: *Movement = undefined };

    count: usize = 0,

    pub fn update(self: *@This(), iter: *Iterator(State, Component)) void {
        while (iter.next()) |state| {
            self.count += 1;
            state.position.x += state.movement.dir_x * state.movement.speed;
            state.position.y += state.movement.dir_y * state.movement.speed;
        }
    }
};

test "Using SparseUnionMultiArrayList for entity component system" {
    var gameState = SparseUnionMultiArrayList(Component).init(std.testing.allocator);
    defer gameState.deinit();

    // Entity #1 has position and movement.
    try gameState.add(Position{ .id = 1, .x = 0, .y = 0 });
    try gameState.add(Movement{ .id = 1, .dir_x = 1, .dir_y = 0, .speed = 10 });

    // Entity #2 has only position (is stationary).
    try gameState.add(Position{ .id = 2, .x = 0, .y = 0 });

    // Entity #3 has position, movement and health.
    try gameState.add(Position{ .id = 3, .x = 0, .y = 0 });
    try gameState.add(Movement{ .id = 3, .dir_x = -1, .dir_y = 0, .speed = 10 });
    try gameState.add(Health{ .id = 3, .points = 100 });

    // Movement system takes in game state of all entities that have position and movement (MovementSystem.State).
    var system = MovementSystem{};
    var iter = Iterator(MovementSystem.State, Component).init(&gameState);
    system.update(&iter);

    // Only two entities: #1 and #3 have both position and state.
    // Therefore system should have updated two entities only.
    try std.testing.expectEqual(2, system.count);

    // Entity #1 was going to the positive direction from 0 -> 10.
    try std.testing.expectEqual(10, gameState.data.position.items[0].x);

    // Entity #2 is stationary, position did not change.
    try std.testing.expectEqual(0, gameState.data.position.items[1].x);

    // Entity #3 was going to the negative direction from 0 -> -10.
    try std.testing.expectEqual(-10, gameState.data.position.items[2].x);
}
