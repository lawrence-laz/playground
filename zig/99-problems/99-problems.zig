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

// #6 Find out whether a list is a palindrome.
fn isPalindrome(list: std.ArrayList(u8)) bool {
    if (list.items.len < 2) {
        return true;
    }
    for (0..list.items.len / 2) |i| {
        if (list.items[i] != list.items[list.items.len - 1 - i]) {
            return false;
        }
    }
    return true;
}

test isPalindrome {
    {
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.append('a');
        try list.append('b');
        try list.append('c');
        try list.append('d');
        try std.testing.expectEqual(isPalindrome(list), false);
    }
    {
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.append('a');
        try list.append('b');
        try list.append('b');
        try list.append('a');
        try std.testing.expectEqual(isPalindrome(list), true);
    }
}

// #7 Flatten a nested list structure.
const NodeTag = enum {
    one,
    many,
};

fn Node(comptime T: type) type {
    return union(NodeTag) {
        one: T,
        many: []Node(T),
    };
}

fn flatten(root: Node(u8), allocator: std.mem.Allocator) !std.ArrayList(u8) {
    var values_list = std.ArrayList(u8).init(allocator);
    var node_stack = std.ArrayList(Node(u8)).init(allocator);
    defer node_stack.deinit();
    try node_stack.append(root);
    while (node_stack.popOrNull()) |node| {
        switch (node) {
            NodeTag.one => |value| try values_list.append(value),
            NodeTag.many => |child_nodes| for (child_nodes) |child_node| {
                try node_stack.append(child_node);
            },
        }
    }
    return values_list;
}

test flatten {
    var grandchildren = [_]Node(u8){ .{ .one = 'b' }, .{ .one = 'c' } };
    var children = [_]Node(u8){ .{ .one = 'a' }, .{ .many = &grandchildren }, .{ .one = 'd' } };
    const root: Node(u8) = .{ .many = &children };
    var flattened = try flatten(root, std.testing.allocator);
    defer flattened.deinit();
    try std.testing.expectEqual(flattened.items.len, 4);
    try std.testing.expectEqual(flattened.items[0], 'd');
    try std.testing.expectEqual(flattened.items[1], 'c');
    try std.testing.expectEqual(flattened.items[2], 'b');
    try std.testing.expectEqual(flattened.items[3], 'a');
}

// #8 Eliminate consecutive duplicates of list elements.
fn removeConsecutiveDuplicates(list: *std.ArrayList(u8)) void {
    var i: usize = 0;
    var previous_value_or_null: ?u8 = null;
    while (i < list.items.len) {
        const current_value = list.items[i];
        if (previous_value_or_null) |previous_value| {
            if (previous_value == current_value) {
                _ = list.orderedRemove(i);
                continue;
            }
        }
        previous_value_or_null = current_value;
        i += 1;
    }
}

test removeConsecutiveDuplicates {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('c');
    try list.append('d');
    removeConsecutiveDuplicates(&list);
    try std.testing.expectEqual(list.items[0], 'a');
    try std.testing.expectEqual(list.items[1], 'b');
    try std.testing.expectEqual(list.items[2], 'c');
    try std.testing.expectEqual(list.items[3], 'd');
    try std.testing.expectEqual(list.items.len, 4);
}

// #9 Pack consecutive duplicates of list elements into sublists.
fn packConsecutiveDuplicatesIntoSublists(comptime T: type, allocator: std.mem.Allocator, list: *std.ArrayList(T)) !std.ArrayList(std.ArrayList(T)) {
    var result = std.ArrayList(std.ArrayList(T)).init(allocator);
    var sublist = std.ArrayList(T).init(allocator);
    var maybePreviousItem: ?T = null;
    for (list.items) |item| {
        if (maybePreviousItem) |previousItem| {
            if (item != previousItem) {
                try result.append(sublist);
                sublist = std.ArrayList(T).init(allocator);
            }
        }
        maybePreviousItem = item;
        try sublist.append(item);
    }
    try result.append(sublist);
    return result;
}

test packConsecutiveDuplicatesIntoSublists {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('c');
    const sublists = try packConsecutiveDuplicatesIntoSublists(u8, std.testing.allocator, &list);
    defer {
        for (sublists.items) |sublist| {
            sublist.deinit();
        }
        sublists.deinit();
    }
    try std.testing.expectEqual(sublists.items[0].items[0], 'a');
    try std.testing.expectEqual(sublists.items[0].items[1], 'a');
    try std.testing.expectEqual(sublists.items[0].items.len, 2);
    try std.testing.expectEqual(sublists.items[1].items[0], 'b');
    try std.testing.expectEqual(sublists.items[1].items.len, 1);
    try std.testing.expectEqual(sublists.items[2].items[0], 'c');
    try std.testing.expectEqual(sublists.items[2].items[1], 'c');
    try std.testing.expectEqual(sublists.items[2].items.len, 2);
}

// #10 Run-length encoding of a list.
fn EncodedEntry(comptime T: type) type {
    return struct {
        item: T,
        count: usize,
    };
}

fn runLengthEncode(comptime T: type, list: *std.ArrayList(T), allocator: std.mem.Allocator) !std.ArrayList(EncodedEntry(T)) {
    var encodedList = std.ArrayList(EncodedEntry(T)).init(allocator);
    if (list.items.len == 0) {
        return encodedList;
    }
    var lastEncodedItem: EncodedEntry(T) = .{
        .item = list.items[0],
        .count = 0,
    };
    for (list.items) |item| {
        if (lastEncodedItem.item != item) {
            try encodedList.append(lastEncodedItem);
            lastEncodedItem = .{
                .item = item,
                .count = 0,
            };
        }
        lastEncodedItem.count += 1;
    }
    if (lastEncodedItem.count != 0) {
        try encodedList.append(lastEncodedItem);
    }
    return encodedList;
}

test runLengthEncode {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('c');
    var encodedList = try runLengthEncode(u8, &list, std.testing.allocator);
    defer encodedList.deinit();
    try std.testing.expectEqual(encodedList.items[0].item, 'a');
    try std.testing.expectEqual(encodedList.items[0].count, 2);
    try std.testing.expectEqual(encodedList.items[1].item, 'b');
    try std.testing.expectEqual(encodedList.items[1].count, 1);
    try std.testing.expectEqual(encodedList.items[2].item, 'c');
    try std.testing.expectEqual(encodedList.items[2].count, 2);
}
