const std = @import("std");

test "playing around with BoundedArray" {
    {
        var array = try std.BoundedArray(i32, 4).init(1);
        // The `len` is immediatelly equal to the value passed to `.init(...)`.
        try std.testing.expectEqual(1, array.len);
        // Same with `slice().len`.
        try std.testing.expectEqual(1, array.slice().len);

        // The initial values are `undefined`?

        // Append can be called untill `len` < `buffer_capacity`.
        try array.append(0);
        try array.append(1);
        try array.append(2);

        try std.testing.expectEqual(4, array.len);
        try std.testing.expectEqual(4, array.slice().len);

        // Calling `.append(...)` beyond the initial `len` gives an error.
        try std.testing.expectError(error.Overflow, array.append(3));
        // Same for `.addOne()`.
        try std.testing.expectError(error.Overflow, array.addOne());

        // Calling `.pop()`, however, reduces `.len`
        _ = array.pop();
        _ = array.pop();
        _ = array.pop();
        _ = array.pop();
        try std.testing.expectEqual(0, array.slice().len);

        // `BoundedArray` can be created without `.init(...)`.
        array = .{};
    }
}
