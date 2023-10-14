// These problems are more suited for functional languages.
// Nevertheless, an exercise always brings some benefit.
// Source: https://v2.ocaml.org/learn/tutorials/99problems.html

const std = @import("std");

// #1 Write a function that returns the last element of a list.
fn last(list: std.ArrayList(u8)) u8 {
    return list.items[list.items.len - 1];
}

test last {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('d');
    try std.testing.expect(last(list) == 'd');
}

// #2 Find the last but one (last and penultimate) elements of a list.
fn lastTwo(list: std.ArrayList(u8)) ?struct { next_to_last: u8, last: u8 } {
    return if (list.items.len >= 2)
        .{ .next_to_last = list.items[list.items.len - 2], .last = list.items[list.items.len - 1] }
    else
        null;
}

test lastTwo {
    {
        // List with many items
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.append('a');
        try list.append('b');
        try list.append('c');
        try list.append('d');
        try std.testing.expect(lastTwo(list).?.next_to_last == 'c');
        try std.testing.expect(lastTwo(list).?.last == 'd');
    }
    {
        // List with a single item
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.append('a');
        try std.testing.expect(lastTwo(list) == null);
    }
}

// #3 Find the N'th element of a list.
fn getNth(list: std.ArrayList(u8), index: usize) ArayAcessError!u8 {
    return if (list.items.len >= index)
        list.items[index]
    else
        error.IndexOutOfRange;
}

const ArayAcessError = error{
    IndexOutOfRange,
};

test getNth {
    {
        // List contains N'th.
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.append('a');
        try list.append('b');
        try list.append('c');
        try list.append('d');
        try std.testing.expectEqual(getNth(list, 1), 'b');
    }
    {
        // List does not contain N'th.
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try std.testing.expectError(ArayAcessError.IndexOutOfRange, getNth(list, 1));
    }
}

// #4 Find the number of elements of a list.
fn length(list: std.ArrayList(u8)) usize {
    var size: usize = 0;
    for (list.items) |_| {
        size += 1;
    }
    return size;
}

test length {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('d');
    try std.testing.expectEqual(length(list), 4);
}

// #5 Reverse a list.
fn reverse(list: std.ArrayList(u8)) void {
    if (list.items.len < 2) {
        return;
    }
    for (0..list.items.len / 2) |i| {
        const temp = list.items[i];
        list.items[i] = list.items[list.items.len - i - 1];
        list.items[list.items.len - i - 1] = temp;
    }
}

test reverse {
    {
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.append('a');
        try list.append('b');
        try list.append('c');
        try list.append('d');
        reverse(list);
        try std.testing.expectEqual(list.items[0], 'd');
        try std.testing.expectEqual(list.items[1], 'c');
        try std.testing.expectEqual(list.items[2], 'b');
        try std.testing.expectEqual(list.items[3], 'a');
    }
    {
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.append('a');
        reverse(list);
        try std.testing.expectEqual(list.items[0], 'a');
    }
}
