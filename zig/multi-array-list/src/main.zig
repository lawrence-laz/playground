const std = @import("std");

const Monster = struct {
    element: enum { fire, water, earth, wind },
    hp: u32,
    foo: ?u256,
};

const MonsterList = std.MultiArrayList(Monster);

test "do optional fields take space?" {
    var soa = MonsterList{};
    defer soa.deinit(std.testing.allocator);

    // Normally you would want to append many monsters
    try soa.append(std.testing.allocator, .{
        .element = .fire,
        .hp = 20,
        .foo = null,
    });

    // Count the number of fire monsters
    var total_fire: usize = 0;
    for (soa.items(.element)) |t| {
        if (t == .fire) total_fire += 1;
    }

    // Heal all monsters
    for (soa.items(.hp)) |*hp| {
        hp.* = 100;
    }

    try std.testing.expectEqual(@as(usize, 1), total_fire);
}
