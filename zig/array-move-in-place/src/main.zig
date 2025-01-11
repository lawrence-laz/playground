const std = @import("std");

fn moveItems(
    comptime T: type,
    slice: []T,
    source_index: usize,
    size: usize,
    target_index: usize,
) void {
    if (source_index < target_index) {
        std.mem.rotate(T, slice[source_index..target_index], size);
    } else {
        std.mem.rotate(T, slice[target_index .. source_index + size], source_index - target_index);
    }
}

test moveItems {
    {
        var items = [_]i32{ 0, 1, 6, 7, 8, 9, 2, 3, 4, 5, 0 };
        moveItems(i32, &items, 6, 4, 2);
        try std.testing.expectEqualSlices(i32, &.{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 }, &items);
    }
    {
        var items = [_]i32{ 0, 1, 6, 2, 3, 4, 5 };
        moveItems(i32, &items, 3, 4, 2);
        try std.testing.expectEqualSlices(i32, &.{ 0, 1, 2, 3, 4, 5, 6 }, &items);
    }
    {
        //                   t-v   s-v-----v
        var items = [_]i32{ 0, 4, 5, 1, 2, 3, 6 };
        moveItems(i32, &items, 3, 3, 1);
        std.log.debug("{any}", .{items});
        try std.testing.expectEqualSlices(i32, &.{ 0, 1, 2, 3, 4, 5, 6 }, &items);
    }
}
