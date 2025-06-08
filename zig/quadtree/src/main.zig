const rl = @import("raylib");
const std = @import("std");

const FreeList = @import("free_list.zig").FreeList;

const Vec2 = struct { x: f32, y: f32 };

// QuadTree -->1 Node (root)
// Node(node) -->4 Node (node/leaf)
// Node(leaf) -->1 Bucket
// Bucket -->* Data       -- This has potential to save index data to avoid data lookup (like in rdbms)
//
// Requirements (red):
// - Indices have to be stable, make sure all operations keep them stable or updated
// - Measure creations, but generally should be fast ~1ms.
// - Try keeping data contigous with data and buckets being single dimensional arrays.
// - Free buckets instead of removal to keep indices and avoid allocs.
// - bucket index implies ovnership of slice data[buckets[bucket_index]..bucket[bucket_index]+bucket_size]
// - red magenta Calculate ram Requirements
//          - take photo of some environment from pinterest
//          - count amount of objects + 5 npc + 5 pc
//              - forested area has about 100 items/trees
//          - multiply by the size of a map (10K x 10K) travian world is 800x800, maybe that's enough? prob
//          - get reasonable amount of memory
//          - red try this with a "forest" area, think about how not to explode the size of this.
//
// addItem(pos, item)                -- find node, if bucket.size > bucket, split then add into leaf
// split(node)                       -- create 4 leaf nodes, move bucket into first and get/create 3 more buckets, distribute items
// remove(pos, item)                 -- find nodes and remove, red could be multiple?
// moveItem(prev_pos, new_pos, item) -- remove+add? red make sure not to miss some node
// getNeighbours(pos)                -- iter?
// getRect(rect)                     -- iter for items in overlaping nodes, be generous with overlap check
// getCircle(circle)                 -- just AABB helper calling getRect
// getCone()                         -- atan2 and https://www.redblobgames.com/grids/circle-drawing/
// getPoint(pos)                     -- iter for items in overlaping nodes
// compact                           -- trim unneeded leaves and combine items (maybe not frequently?)
pub fn QuadTree(comptime T: type, comptime bucket_size: usize) type {
    return struct {
        size: Vec2,
        nodes: FreeList([4]Node),
        buckets: FreeList(Bucket),
        root: Node,

        pub fn init(
            allocator: std.mem.Allocator,
            size: Vec2,
        ) !QuadTree(T, bucket_size) {
            var buckets: FreeList(Bucket) = .{};
            const nw_bucket_index = try buckets.add(allocator, .{});
            const ne_bucket_index = try buckets.add(allocator, .{});
            const sw_bucket_index = try buckets.add(allocator, .{});
            const se_bucket_index = try buckets.add(allocator, .{});

            var nodes: FreeList([4]Node) = .{};
            const child_nodes_index = try nodes.add(allocator, .{
                .{ .leaf = .{ .bucket_index = nw_bucket_index } },
                .{ .leaf = .{ .bucket_index = ne_bucket_index } },
                .{ .leaf = .{ .bucket_index = sw_bucket_index } },
                .{ .leaf = .{ .bucket_index = se_bucket_index } },
            });

            return .{
                .size = size,
                .nodes = nodes,
                .buckets = buckets,
                .root = .{ .node = .{ .child_node_index = child_nodes_index } },
            };
        }

        pub fn deinit(quad_tree: *QuadTree(T, bucket_size), allocator: std.mem.Allocator) void {
            quad_tree.nodes.deinit(allocator);
            quad_tree.buckets.deinit(allocator);
        }

        pub fn add(
            quad_tree: *QuadTree(T, bucket_size),
            allocator: std.mem.Allocator,
            pos: Vec2,
            item: T,
        ) !void {
            var node = &quad_tree.root;
            var center: Vec2 = .{ .x = quad_tree.size.x / 2, .y = quad_tree.size.y / 2 };
            var prev_center: Vec2 = quad_tree.size;

            while (std.meta.activeTag(node.*) == .node) {
                const child_node_index = node.node.child_node_index;
                const children = quad_tree.nodes.atPtr(child_node_index);
                const half_size = @abs(center.x - prev_center.x) / 2;
                prev_center = center;

                if (pos.x < center.x and pos.y < center.y) {
                    node = &children[0];
                    center = .{ .x = center.x - half_size, .y = center.y - half_size };
                } else if (pos.x >= center.x and pos.y < center.y) {
                    node = &children[1];
                    center = .{ .x = center.x + half_size, .y = center.y - half_size };
                } else if (pos.x < center.x and pos.y >= center.y) {
                    node = &children[2];
                    center = .{ .x = center.x - half_size, .y = center.y + half_size };
                } else if (pos.x >= center.x and pos.y >= center.y) {
                    node = &children[3];
                    center = .{ .x = center.x + half_size, .y = center.y + half_size };
                }
            }
            var bucket = quad_tree.buckets.atPtr(node.leaf.bucket_index);
            // const free_index = std.mem.indexOfScalar(?Item, &bucket.items, null) orelse blk: {
            const free_index = indexOfEmpty(&bucket.items) orelse blk: {
                const new_child_nodes_index = try quad_tree.nodes.add(allocator, .{
                    node.*,
                    .{ .leaf = .{ .bucket_index = try quad_tree.buckets.add(allocator, .{}) } },
                    .{ .leaf = .{ .bucket_index = try quad_tree.buckets.add(allocator, .{}) } },
                    .{ .leaf = .{ .bucket_index = try quad_tree.buckets.add(allocator, .{}) } },
                });

                const new_child_nodes = quad_tree.nodes.atPtr(new_child_nodes_index);
                var nw_bucket = quad_tree.buckets.atPtr(new_child_nodes[0].leaf.bucket_index);
                var ne_bucket = quad_tree.buckets.atPtr(new_child_nodes[1].leaf.bucket_index);
                var sw_bucket = quad_tree.buckets.atPtr(new_child_nodes[2].leaf.bucket_index);
                var se_bucket = quad_tree.buckets.atPtr(new_child_nodes[3].leaf.bucket_index);

                for (&nw_bucket.items, 0..) |*maybe_nw_item, i| {
                    if (maybe_nw_item.*) |nw_item| {
                        if (nw_item.pos.x < center.x and nw_item.pos.y < center.y) {
                            // Already in a correct bucket.
                            continue;
                        } else if (nw_item.pos.x >= center.x and nw_item.pos.y < center.y) {
                            // TODO: Kind of sucks to search for empty spot each time. Maybe need FreeArray?
                            // const new_index = std.mem.indexOfScalar(?Item, &ne_bucket.items, null).?;
                            const new_index = indexOfEmpty(&ne_bucket.items).?;
                            ne_bucket.items[new_index] = nw_item;
                        } else if (nw_item.pos.x < center.x and nw_item.pos.y >= center.y) {
                            // TODO: Kind of sucks to search for empty spot each time. Maybe need FreeArray?
                            // const new_index = std.mem.indexOfScalar(?Item, &sw_bucket.items, null).?;
                            const new_index = indexOfEmpty(&sw_bucket.items).?;
                            sw_bucket.items[new_index] = nw_item;
                        } else if (nw_item.pos.x >= center.x and nw_item.pos.y >= center.y) {
                            // TODO: Kind of sucks to search for empty spot each time. Maybe need FreeArray?
                            // const new_index = std.mem.indexOfScalar(?Item, &se_bucket.items, null).?;
                            const new_index = indexOfEmpty(&se_bucket.items).?;
                            se_bucket.items[new_index] = nw_item;
                        }
                        nw_bucket.items[i] = null;
                    }
                }

                node.* = .{ .node = .{ .child_node_index = new_child_nodes_index } };

                bucket = if (pos.x < center.x and pos.y < center.y)
                    nw_bucket
                else if (pos.x >= center.x and pos.y < center.y)
                    ne_bucket
                else if (pos.x < center.x and pos.y >= center.y)
                    sw_bucket
                else if (pos.x >= center.x and pos.y >= center.y)
                    se_bucket
                else
                    unreachable;

                break :blk indexOfEmpty(&bucket.items).?;
                // break :blk std.mem.indexOfScalar(?Item, &bucket.items, null).?;
            };
            bucket.items[free_index] = .{ .pos = pos, .value = item };
        }

        fn indexOfEmpty(slice: anytype) ?usize {
            for (slice, 0..) |maybe_item, i| {
                if (maybe_item) |_| continue;
                return i;
            }
            return null;
        }

        pub fn iterLeaf(quad_tree: *QuadTree(T, bucket_size)) IterLeaf {
            var stack: std.BoundedArray(IterLeaf.IterLeafState, 64) = .{};
            stack.append(.{
                .node = &quad_tree.root,
                .child_index = 0,
                .node_pos = .{ .x = 0, .y = 0 },
                .node_size = quad_tree.size.x,
            }) catch unreachable;
            return .{ .quad_tree = quad_tree, .stack = stack, .bucket_index = 0 };
        }

        pub const IterLeaf = struct {
            quad_tree: *QuadTree(T, bucket_size),
            stack: std.BoundedArray(IterLeafState, 64),
            bucket_index: usize,

            pub fn next(iter: *@This()) ?IterLeafItem {
                if (iter.stack.len == 0) {
                    // Iter completed.
                    std.log.debug("hmm", .{});
                    return null;
                }

                const current: *IterLeafState = &iter.stack.slice()[iter.stack.len - 1];
                defer current.child_index += 1;

                if (current.child_index >= 4) {
                    // Current node completed.
                    _ = iter.stack.pop();
                    return iter.next();
                }

                const child = &iter.quad_tree.nodes.atPtr(current.node.node.child_node_index)[current.child_index];
                switch (child.*) {
                    Node.node => {
                        // Push node to stack to visit all descendants.
                        const half_size = current.node_size / 2;
                        const pos: Vec2 = if (current.child_index == 0)
                            .{ .x = current.node_pos.x - half_size, .y = current.node_pos.y - half_size }
                        else if (current.child_index == 1)
                            .{ .x = current.node_pos.x + half_size, .y = current.node_pos.y - half_size }
                        else if (current.child_index == 2)
                            .{ .x = current.node_pos.x - half_size, .y = current.node_pos.y + half_size }
                        else if (current.child_index == 3)
                            .{ .x = current.node_pos.x + half_size, .y = current.node_pos.y + half_size }
                        else
                            unreachable;

                        iter.stack.append(.{
                            .node = child,
                            .child_index = 0,
                            .node_pos = pos,
                            .node_size = half_size,
                        }) catch @panic("IterLeaf stack ran out of space");
                        return iter.next();
                    },
                    Node.leaf => |leaf| {
                        const bucket = iter.quad_tree.buckets.at(leaf.bucket_index);
                        while (iter.bucket_index < bucket.items.len) : (iter.bucket_index += 1) {
                            if (bucket.items[iter.bucket_index]) |*item| {
                                return .{ .item = item, .node_pos = current.node_pos, .node_size = current.node_size };
                            }
                        } else {
                            // Leaf fully iterated.
                            current.child_index += 1;
                            iter.bucket_index = 0;
                            return iter.next();
                        }
                    },
                }
            }

            pub const IterLeafState = struct {
                node: *const Node,
                child_index: usize,
                node_pos: Vec2,
                node_size: f32,
            };

            pub const IterLeafItem = struct {
                item: *const Item,
                node_pos: Vec2,
                node_size: f32,
            };
        };

        const Node = union(enum) {
            node: struct { child_node_index: usize },
            leaf: struct { bucket_index: usize },
        };

        const Item = struct {
            pos: Vec2,
            value: T,
        };

        const Bucket = struct {
            items: [bucket_size]?Item = .{null} ** bucket_size,
        };
    };
}

test "foo" {
    var foo = try QuadTree(i32, 3).init(std.testing.allocator, .{ .x = 100, .y = 100 });
    defer foo.deinit(std.testing.allocator);
    _ = try foo.add(std.testing.allocator, .{ .x = 10, .y = 10 }, 123);
    _ = try foo.add(std.testing.allocator, .{ .x = 20, .y = 10 }, 123);
    _ = try foo.add(std.testing.allocator, .{ .x = 40, .y = 10 }, 123);
    _ = try foo.add(std.testing.allocator, .{ .x = 45, .y = 10 }, 123);
    _ = try foo.add(std.testing.allocator, .{ .x = 50, .y = 10 }, 123);

    // TODO: iter doesn't go through all?
    // inspeciting through debugger seems to show all items in correct buckets.
    var iter = foo.iterLeaf();
    while (iter.next()) |item| {
        _ = item;
    }
}

pub fn main() anyerror!void {
    const screen_width = 800;
    const screen_height = 800;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    // TODO: Require square size?
    var quad_tree = try QuadTree(rl.Vector2, 3).init(allocator, .{ .x = screen_width, .y = screen_height });

    rl.initWindow(screen_width, screen_height, "Quadtree");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var gen_time_buf: [100]u8 = .{0} ** 100;
    var text: [*:0]u8 = undefined;

    while (!rl.windowShouldClose()) {
        const start_frame_time = std.time.nanoTimestamp();
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);

        if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
            const mouse_pos = rl.getMousePosition();
            const pos: Vec2 = .{ .x = mouse_pos.x, .y = mouse_pos.y };
            try quad_tree.add(allocator, pos, mouse_pos);
        }

        var items_count: usize = 0;
        var buckets = quad_tree.buckets.iter();
        while (buckets.next()) |bucket| {
            for (bucket.items) |maybe_item| {
                if (maybe_item) |item| {
                    rl.drawCircleV(.{ .x = item.pos.x, .y = item.pos.y }, 3, rl.Color.red);
                    // rl.drawRectangle(@intFromFloat(item.pos.x), @intFromFloat(item.pos.y), 50, 50, rl.Color.red);
                    items_count += 1;
                }
            }
        }

        var nodes_count: usize = 0;
        var nodes = quad_tree.nodes.iter();
        while (nodes.next()) |_| {
            nodes_count += 1;
        }

        // ITER
        // var iter = quad_tree.iterLeaf();
        // while (iter.next()) |item| {
        //     rl.drawRectangleLines(
        //         @intFromFloat(item.node_pos.x),
        //         @intFromFloat(item.node_pos.y),
        //         @intFromFloat(item.node_size),
        //         @intFromFloat(item.node_size),
        //         rl.Color.gray,
        //     );
        //     rl.drawCircleV(.{ .x = item.item.pos.x, .y = item.item.pos.y }, 3, rl.Color.red);
        //     items_count += 1;
        // }

        const end_frame_time = std.time.nanoTimestamp();
        text = try std.fmt.bufPrintZ(
            &gen_time_buf,
            "Frame took {s}",
            .{std.fmt.fmtDuration(@intCast(end_frame_time - start_frame_time))},
        );
        rl.drawText(text, 190, 200, 20, rl.Color.light_gray);

        text = try std.fmt.bufPrintZ(&gen_time_buf, "items_count={d}", .{items_count});
        rl.drawText(text, 0, 0, 15, rl.Color.light_gray);

        text = try std.fmt.bufPrintZ(&gen_time_buf, "nodes_count={d}", .{nodes_count});
        rl.drawText(text, 0, 20, 15, rl.Color.light_gray);
    }
}
