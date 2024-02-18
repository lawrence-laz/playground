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

// #11 Modified run-length encoding.
const EncodedItemTag = enum {
    one,
    many,
};

fn EncodedItem(comptime T: type) type {
    return union(EncodedItemTag) {
        one: T,
        many: EncodedEntry(T),
    };
}

fn modifiedRunLengthEncode(comptime T: type, list: *std.ArrayList(T), allocator: std.mem.Allocator) !std.ArrayList(EncodedItem(T)) {
    var encodedList = std.ArrayList(EncodedItem(T)).init(allocator);
    if (list.items.len == 0) {
        return encodedList;
    }
    var lastEncodedItem: EncodedItem(T) = .{ .many = .{
        .item = list.items[0],
        .count = 0,
    } };
    for (list.items) |item| {
        if (lastEncodedItem.many.item != item) {
            if (lastEncodedItem.many.count == 1) {
                try encodedList.append(.{ .one = lastEncodedItem.many.item });
            } else {
                try encodedList.append(lastEncodedItem);
            }
            lastEncodedItem = .{ .many = .{
                .item = item,
                .count = 0,
            } };
        }
        lastEncodedItem.many.count += 1;
    }
    if (lastEncodedItem.many.count == 1) {
        try encodedList.append(.{ .one = lastEncodedItem.many.item });
    } else if (lastEncodedItem.many.count > 1) {
        try encodedList.append(lastEncodedItem);
    }
    return encodedList;
}

test modifiedRunLengthEncode {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('c');
    var encodedList = try modifiedRunLengthEncode(u8, &list, std.testing.allocator);
    defer encodedList.deinit();
    try std.testing.expectEqual(encodedList.items[0].many, EncodedEntry(u8){ .item = 'a', .count = 2 });
    try std.testing.expectEqual(encodedList.items[1].one, 'b');
    try std.testing.expectEqual(encodedList.items[2].many, EncodedEntry(u8){ .item = 'c', .count = 2 });
}

// #12 Decode a run-length encoded list.
fn decodeRunLength(comptime T: type, encodedList: *std.ArrayList(EncodedItem(T)), allocator: std.mem.Allocator) !std.ArrayList(T) {
    var decoded_list = std.ArrayList(T).init(allocator);
    for (encodedList.items) |encoded_item| {
        switch (encoded_item) {
            EncodedItemTag.one => {
                try decoded_list.append(encoded_item.one);
            },
            EncodedItemTag.many => {
                for (0..encoded_item.many.count) |_| {
                    try decoded_list.append(encoded_item.many.item);
                }
            },
        }
    }
    return decoded_list;
}

test decodeRunLength {
    var encoded_list = std.ArrayList(EncodedItem(u8)).init(std.testing.allocator);
    defer encoded_list.deinit();
    try encoded_list.append(.{ .many = .{ .count = 2, .item = 'a' } });
    try encoded_list.append(.{ .one = 'b' });
    try encoded_list.append(.{ .many = .{ .count = 2, .item = 'c' } });
    var decoded_list = try decodeRunLength(u8, &encoded_list, std.testing.allocator);
    defer decoded_list.deinit();
    try std.testing.expectEqual(decoded_list.items[0], 'a');
    try std.testing.expectEqual(decoded_list.items[1], 'a');
    try std.testing.expectEqual(decoded_list.items[2], 'b');
    try std.testing.expectEqual(decoded_list.items[3], 'c');
    try std.testing.expectEqual(decoded_list.items[4], 'c');
}

// #13. Run-length encoding of a list (direct solution).
// Duplicate of #11.

// #14. Duplicate the elements of a list.
fn duplicateElements(comptime T: type, list: *std.ArrayList(T), allocator: std.mem.Allocator) !std.ArrayList(T) {
    var duplicated_list = try std.ArrayList(T).initCapacity(allocator, list.items.len * 2);
    for (list.items) |item| {
        try duplicated_list.append(item);
        try duplicated_list.append(item);
    }
    return duplicated_list;
}

test duplicateElements {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('c');
    try list.append('d');
    var duplicated_list = try duplicateElements(u8, &list, std.testing.allocator);
    defer duplicated_list.deinit();
    try std.testing.expectEqualSlices(u8, duplicated_list.items, &[_]u8{ 'a', 'a', 'b', 'b', 'c', 'c', 'c', 'c', 'd', 'd' });
}

// #15. Replicate the elements of a list a given number of times.
fn replicate(comptime T: type, list: *std.ArrayList(T), count: usize, allocator: std.mem.Allocator) !std.ArrayList(T) {
    var replicated_list = try std.ArrayList(T).initCapacity(allocator, list.items.len * count);
    for (list.items) |item| {
        for (0..count) |_| {
            try replicated_list.append(item);
        }
    }
    return replicated_list;
}

test replicate {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('b');
    try list.append('c');
    var replicated_list = try replicate(u8, &list, 3, std.testing.allocator);
    defer replicated_list.deinit();
    try std.testing.expectEqualSlices(u8, replicated_list.items, &[_]u8{ 'a', 'a', 'a', 'b', 'b', 'b', 'c', 'c', 'c' });
}

// #16. Drop every N'th element from a list.
fn dropEveryNth(comptime T: type, list: *std.ArrayList(T), n: usize) void {
    var index: usize = n - 1;
    while (index < list.items.len) {
        _ = list.orderedRemove(index);
        index += n - 1;
    }
}

test dropEveryNth {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('d');
    try list.append('e');
    try list.append('f');
    try list.append('g');
    try list.append('h');
    try list.append('i');
    try list.append('j');
    dropEveryNth(u8, &list, 3);
    try std.testing.expectEqualSlices(u8, list.items, &[_]u8{ 'a', 'b', 'd', 'e', 'g', 'h', 'j' });
}

// #17. Split a list into two parts; the length of the first part is given.
fn split(comptime T: type, list: *std.ArrayList(T), split_size: usize) struct { first: ?[]T, second: ?[]T } {
    const first_size = @min(list.items.len, split_size);
    const first = if (first_size > 0) list.items[0..first_size] else null;
    const second = if (split_size < list.items.len) list.items[split_size..] else null;
    return .{ .first = first, .second = second };
}

test "split both populated" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('d');
    try list.append('e');
    try list.append('f');
    try list.append('g');
    try list.append('h');
    try list.append('i');
    try list.append('j');
    const result = split(u8, &list, 3);
    try std.testing.expectEqualSlices(u8, result.first.?, &[_]u8{ 'a', 'b', 'c' });
    try std.testing.expectEqualSlices(u8, result.second.?, &[_]u8{ 'd', 'e', 'f', 'g', 'h', 'i', 'j' });
}

test "split second empty" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append('a');
    try list.append('b');
    try list.append('c');
    try list.append('d');
    const result = split(u8, &list, 5);
    try std.testing.expectEqualSlices(u8, result.first.?, &[_]u8{ 'a', 'b', 'c', 'd' });
    try std.testing.expectEqual(result.second, null);
}

// #18. Extract a slice from a list.
fn getSlice(comptime T: type, list: *std.ArrayList(T), start: usize, end: usize) ![]T {
    if (start >= list.items.len or end >= list.items.len) {
        return error.IndexOutOfRange;
    }
    return list.items[start .. end + 1];
}

test getSlice {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.appendSlice(&[_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j' });
    const actual = try getSlice(u8, &list, 2, 6);
    try std.testing.expectEqualSlices(u8, actual, &[_]u8{ 'c', 'd', 'e', 'f', 'g' });

    try std.testing.expectError(error.IndexOutOfRange, getSlice(u8, &list, 10, 11));
    try std.testing.expectError(error.IndexOutOfRange, getSlice(u8, &list, 9, 10));
}

fn reverseSlice(comptime T: type, list: []T) void {
    if (list.len < 2) {
        return;
    }
    for (0..list.len / 2) |i| {
        const temp = list[i];
        list[i] = list[list.len - i - 1];
        list[list.len - i - 1] = temp;
    }
}

// #19. Rotate a list N places to the left (or right).
fn rotate(comptime T: type, list: *std.ArrayList(T), offset: i32) void {
    const list_length: i32 = @intCast(list.items.len);
    const offset_truncated: usize = @intCast(@mod(offset, list_length));
    const offset_sign = std.math.sign(offset);
    if (offset_sign == 1) {
        reverseSlice(T, list.items[0 .. list.items.len - offset_truncated]);
        reverseSlice(T, list.items[list.items.len - offset_truncated ..]);
        reverseSlice(T, list.items);
    } else if (offset_sign == -1) {
        reverseSlice(T, list.items[0..offset_truncated]);
        reverseSlice(T, list.items[offset_truncated..]);
        reverseSlice(T, list.items);
    } else {
        // Zero offset, do nothing.
    }
}

test rotate {
    {
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.appendSlice(&[_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' });
        rotate(u8, &list, -5);
        try std.testing.expectEqualSlices(u8, list.items, &[_]u8{ 'd', 'e', 'f', 'g', 'h', 'a', 'b', 'c' });
    }
    {
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.appendSlice(&[_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' });
        rotate(u8, &list, 2);
        try std.testing.expectEqualSlices(u8, list.items, &[_]u8{ 'g', 'h', 'a', 'b', 'c', 'd', 'e', 'f' });
    }
    {
        var list = std.ArrayList(u8).init(std.testing.allocator);
        defer list.deinit();
        try list.appendSlice(&[_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' });
        rotate(u8, &list, 0);
        try std.testing.expectEqualSlices(u8, list.items, &[_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' });
    }
}

// #20. Remove the K'th element from a list.
// Using these trivial ones as an opportunity to learn standard lib.
fn removeKth(comptime T: type, list: *std.ArrayList(T), remove_index: usize) void {
    _ = list.orderedRemove(remove_index);
}

test removeKth {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.appendSlice("abcd");
    removeKth(u8, &list, 1);
    try std.testing.expectEqualSlices(u8, list.items, "acd");
}

// #21. Insert an element at a given position into a list.
const String = []const u8;
fn insert(comptime T: type, list: *std.ArrayList(T), item: T, index: usize) !void {
    try list.insert(index, item);
}

test insert {
    {
        var list = std.ArrayList(String).init(std.testing.allocator);
        defer list.deinit();
        try list.appendSlice(&[_]String{ "a", "b", "c", "d" });
        try insert(String, &list, "alfa", 1);
        try std.testing.expectEqualSlices(String, list.items, &[_]String{ "a", "alfa", "b", "c", "d" });
    }
    {
        var list = std.ArrayList(String).init(std.testing.allocator);
        defer list.deinit();
        try list.appendSlice(&[_]String{ "a", "b", "c", "d" });
        try insert(String, &list, "alfa", 3);
        try std.testing.expectEqualSlices(String, list.items, &[_]String{ "a", "b", "c", "alfa", "d" });
    }
    {
        var list = std.ArrayList(String).init(std.testing.allocator);
        defer list.deinit();
        try list.appendSlice(&[_]String{ "a", "b", "c", "d" });
        try insert(String, &list, "alfa", 4);
        try std.testing.expectEqualSlices(String, list.items, &[_]String{ "a", "b", "c", "d", "alfa" });
    }
}

// #22. Create a list containing all integers within a given range.
inline fn range(comptime from: i32, comptime to: i32) [@abs(to - from) + 1]i32 {
    const size = @abs(to - from) + 1;
    comptime {
        var range_values: [size]i32 = undefined;
        const direction = std.math.sign(to - from);
        for (0..size) |i| {
            const index: i32 = @intCast(i);
            range_values[i] = from + index * direction;
        }
        return range_values;
    }
}

test range {
    try std.testing.expectEqualSlices(i32, &range(4, 9), &[_]i32{ 4, 5, 6, 7, 8, 9 });
    try std.testing.expectEqualSlices(i32, &range(9, 4), &[_]i32{ 9, 8, 7, 6, 5, 4 });
}

// #23. Extract a given number of randomly selected elements from a list.
// Note, this would need a seed param to be useful outside of this exercise.
fn contains(comptime T: type, slice: []const T, seek_value: T) bool {
    for (slice) |value| {
        if (value == seek_value) {
            return true;
        }
    }
    return false;
}

fn randSelect(comptime T: type, items: []const T, size: usize, allocator: std.mem.Allocator) ![]T {
    var indices = std.ArrayList(usize).init(allocator);
    defer indices.deinit();
    var result = std.ArrayList(T).init(allocator);
    var generator = std.rand.DefaultPrng.init(0);
    for (0..size) |i| {
        var random_index = generator.random().uintLessThan(usize, items.len);
        while (contains(usize, indices.items[0..i], random_index)) {
            random_index = generator.random().uintLessThan(usize, items.len);
        }
        try indices.append(random_index);
        try result.append(items[random_index]);
    }
    return try result.toOwnedSlice();
}

test randSelect {
    const randSlice = try randSelect(u8, &[_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' }, 3, std.testing.allocator);
    defer std.testing.allocator.free(randSlice);
    try std.testing.expectEqualSlices(u8, randSlice, &[_]u8{ 'c', 'd', 'a' });
}

// #24. Lotto: Draw N different random numbers from the set 1..M. (easy)
fn lotto_select(count: usize, max_number: usize, allocator: std.mem.Allocator) ![]usize {
    var result = std.ArrayList(usize).init(allocator);
    var generator = std.rand.DefaultPrng.init(0);
    for (0..count) |_| {
        var drawn_number = generator.random().uintAtMost(usize, max_number);
        while (contains(usize, result.items, drawn_number)) {
            drawn_number = generator.random().uintAtMost(usize, max_number);
        }
        try result.append(drawn_number);
    }
    return result.toOwnedSlice();
}

test lotto_select {
    const drawn_numbers = try lotto_select(6, 49, std.testing.allocator);
    defer std.testing.allocator.free(drawn_numbers);
    try std.testing.expectEqualSlices(usize, drawn_numbers, &[_]usize{ 16, 19, 17, 0, 24, 1 });
}

// #25. Generate a random permutation of the elements of a list.
// Algorithm P (Shuffling), note that actual use, the function should accept a randomization seed.
fn shuffle(comptime T: type, slice: []T) void {
    var generator = std.rand.DefaultPrng.init(0);
    var i = slice.len - 1;
    while (i >= 1) : (i -= 1) {
        const random_index = generator.random().uintAtMost(usize, i);
        const temp = slice[i];
        slice[i] = slice[random_index];
        slice[random_index] = temp;
    }
}

test shuffle {
    var list = [_]u8{ 'a', 'b', 'c', 'd' };
    list[1] = 'q';
    shuffle(u8, &list);
    try std.testing.expectEqualSlices(u8, &list, "cadq");
}

// #26. Generate the combinations of K distinct objects chosen from the N elements of a list.
// This uses Twiddle algorithm https://dl.acm.org/doi/10.1145/362384.362502.
fn combinations(comptime T: type, slice: []const T, take_count: usize, allocator: std.mem.Allocator) ![][]T {
    var result = std.ArrayList([]T).init(allocator);
    const N: usize = slice.len;
    const K: usize = take_count;
    var i: usize = 0;
    var x: usize = 0;
    var y: usize = 0;
    var z: i32 = 0;
    const p: []i32 = try allocator.alloc(i32, N + 2);
    var b: []i32 = try allocator.alloc(i32, N);
    inittwiddle(K, N, p);
    var combination: []T = try allocator.alloc(T, take_count);
    var combination_index: usize = 0;
    while (i != N - K) : (i += 1) {
        b[i] = 0;
    }
    while (i != N) : (i += 1) {
        b[i] = 1;
        combination[combination_index] = slice[i];
        combination_index += 1;
    }
    try result.append(combination);
    while (!twiddle(&x, &y, &z, p)) {
        combination = try allocator.alloc(T, take_count);
        combination_index = 0;
        b[x] = 1;
        b[y] = 0;
        i = 0;
        while (i != N) : (i += 1) {
            if (b[i] != 0) {
                combination[combination_index] = slice[i];
                combination_index += 1;
            }
        }
        try result.append(combination);
    }
    allocator.free(p);
    allocator.free(b);
    return result.toOwnedSlice();
}

fn twiddle(x: *usize, y: *usize, z: *i32, p: []i32) bool {
    var i: usize = 0;
    var j: usize = 1;
    var k: usize = 0;
    while (p[j] <= 0) {
        j += 1;
    }
    if (p[j - 1] == 0) {
        i = j - 1;
        while (i != 1) : (i -= 1) {
            p[i] = -1;
        }
        p[j] = 0;
        x.* = 0;
        z.* = 0;
        p[1] = 1;
        y.* = j - 1;
    } else {
        if (j > 1) {
            p[j - 1] = 0;
        }
        j += 1;
        while (p[j] > 0) : (j += 1) {}
        k = j - 1;
        i = j;
        while (p[i] == 0) {
            p[i] = -1;
            i += 1;
        }
        if (p[i] == -1) {
            p[i] = p[k];
            z.* = p[k] - 1;
            x.* = i - 1;
            y.* = k - 1;
            p[k] = -1;
        } else {
            if (i == p[0]) {
                return true;
            } else {
                p[j] = p[i];
                z.* = p[i] - 1;
                p[i] = 0;
                x.* = j - 1;
                y.* = i - 1;
            }
        }
    }

    return false;
}

fn inittwiddle(m: usize, n: usize, p: []i32) void {
    var i: usize = 1;
    p[0] = @as(i32, @intCast(n)) + 1;
    while (i != n - m + 1) : (i += 1) {
        p[i] = 0;
    }
    while (i != n + 1) {
        p[i] = @as(i32, @intCast(i + m - n));
        i += 1;
    }
    p[n + 1] = -2;
    if (m == 0) {
        p[1] = 1;
    }
}

test combinations {
    const input = "abcde";
    const result = try combinations(u8, input, 2, std.testing.allocator);
    defer {
        for (result) |combination| {
            std.testing.allocator.free(combination);
        }
        std.testing.allocator.free(result);
    }
    try std.testing.expectEqual(result.len, 10);
    try std.testing.expectEqualSlices(u8, result[0], "de");
    try std.testing.expectEqualSlices(u8, result[1], "ae");
    try std.testing.expectEqualSlices(u8, result[2], "be");
    try std.testing.expectEqualSlices(u8, result[3], "ce");
    try std.testing.expectEqualSlices(u8, result[4], "cd");
    try std.testing.expectEqualSlices(u8, result[5], "ad");
    try std.testing.expectEqualSlices(u8, result[6], "bd");
    try std.testing.expectEqualSlices(u8, result[7], "bc");
    try std.testing.expectEqualSlices(u8, result[8], "ac");
    try std.testing.expectEqualSlices(u8, result[9], "ab");
}

test "#27. Group the elements of a set into disjoint subsets. (medium)" {
    const input = "abcd";
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var arena_allocator = std.heap.ArenaAllocator.init(gpa);
    const allocator = arena_allocator.allocator();
    defer arena_allocator.deinit();
    var results = std.ArrayList([][]u8).init(allocator);

    const groups_of_2 = try combinations(u8, input, 2, allocator);
    for (groups_of_2) |group_of_2| {
        var remaining = std.ArrayList(u8).init(allocator);
        for (input) |input_char| {
            if (std.mem.indexOf(u8, group_of_2, &[_]u8{input_char})) |_| {} else {
                try remaining.append(input_char);
            }
        }

        const groups_of_1 = try combinations(u8, remaining.items, 1, allocator);
        for (groups_of_1) |group_of_1| {
            var result = std.ArrayList([]u8).init(allocator);
            try result.append(group_of_2);
            try result.append(group_of_1);
            try results.append(result.items);
        }
    }

    const expected: []const []const []const u8 = &.{
        &.{ "cd", "b" },
        &.{ "cd", "a" },
        &.{ "ad", "c" },
        &.{ "ad", "b" },
        &.{ "bd", "c" },
        &.{ "bd", "a" },
        &.{ "bc", "d" },
        &.{ "bc", "a" },
        &.{ "ac", "d" },
        &.{ "ac", "b" },
        &.{ "ab", "d" },
        &.{ "ab", "c" },
    };

    try std.testing.expectEqualDeep(expected, results.items);
}

fn groups(
    comptime T: type,
    items: []const T,
    group_sizes: []const usize,
    allocator: std.mem.Allocator,
) ![]const []const []const usize {
    var results = std.ArrayList([]const []const usize).init(allocator);
    const grouped_groups = std.ArrayList([]const usize).init(allocator);
    const context = GroupsContext{
        .allocator = allocator,
        .group_sizes = group_sizes,
        .group_index = 0,
        .ungrouped_items = try range_usize(0, items.len, allocator),
        .grouped_groups = grouped_groups.items,
        .results = &results,
    };
    try groupsRecurse(context);
    return results.items;
}

const GroupsContext = struct {
    allocator: std.mem.Allocator,
    group_sizes: []const usize,
    group_index: usize,
    ungrouped_items: []const usize,
    grouped_groups: []const []const usize,
    results: *std.ArrayList([]const []const usize),
};

fn groupsRecurse(context: GroupsContext) !void {
    const group_size = context.group_sizes[context.group_index];
    const group_variants = try combinations(
        usize,
        context.ungrouped_items,
        group_size,
        context.allocator,
    );
    for (group_variants) |group| {
        var next_ungrouped_items = std.ArrayList(usize).init(context.allocator);
        for (context.ungrouped_items) |ungrouped_item| {
            if (std.mem.indexOf(usize, group, &.{ungrouped_item})) |_| {} else {
                try next_ungrouped_items.append(ungrouped_item);
            }
        }
        var next_grouped_groups = std.ArrayList([]const usize).init(context.allocator);
        try next_grouped_groups.appendSlice(context.grouped_groups);
        try next_grouped_groups.append(group);
        const next_context = GroupsContext{
            .allocator = context.allocator,
            .group_sizes = context.group_sizes,
            .group_index = context.group_index + 1,
            .ungrouped_items = next_ungrouped_items.items,
            .grouped_groups = next_grouped_groups.items,
            .results = context.results,
        };

        if (next_context.group_index < context.group_sizes.len) {
            try groupsRecurse(next_context);
        } else {
            try context.results.append(next_grouped_groups.items);
        }
    }
}

inline fn range_usize(from: usize, to: usize, allocator: std.mem.Allocator) ![]usize {
    const size = @abs(to - from);
    var range_values = std.ArrayList(usize).init(allocator);
    for (0..size) |i| {
        try range_values.append(from + i);
    }
    return range_values.items;
}

test "#27. Generalize the above function in a way that we can specify a list of group sizes and the function will return a list of groups." {
    const input = "abcd";
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var arena_allocator = std.heap.ArenaAllocator.init(gpa);
    const allocator = arena_allocator.allocator();
    defer arena_allocator.deinit();

    const results = try groups(u8, input, &.{ 2, 1 }, allocator);

    const expected: []const []const []const u8 = &.{
        &.{ "cd", "b" },
        &.{ "cd", "a" },
        &.{ "ad", "c" },
        &.{ "ad", "b" },
        &.{ "bd", "c" },
        &.{ "bd", "a" },
        &.{ "bc", "d" },
        &.{ "bc", "a" },
        &.{ "ac", "d" },
        &.{ "ac", "b" },
        &.{ "ab", "d" },
        &.{ "ab", "c" },
    };

    var actual = std.ArrayList([]const []const u8).init(allocator);
    for (results) |group_variants| {
        var group_variants_mutated = std.ArrayList([]const u8).init(allocator);
        for (group_variants) |group| {
            var group_mutated = std.ArrayList(u8).init(allocator);
            for (group) |index| {
                try group_mutated.append(input[index]);
            }
            try group_variants_mutated.append(group_mutated.items);
        }
        try actual.append(group_variants_mutated.items);
    }

    try std.testing.expectEqualDeep(expected, actual.items);
}
