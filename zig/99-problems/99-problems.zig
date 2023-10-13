const std = @import("std");

fn last(list: std.ArrayList(u8)) u8 {
    return list.items[list.items.len - 1];
}

// #1
test last {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('d');
    try std.testing.expect(last(list) == 'd');
}
