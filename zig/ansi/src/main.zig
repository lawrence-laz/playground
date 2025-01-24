const std = @import("std");

pub fn magenta(comptime string: []const u8) []const u8 {
    return "\x1b[35m" ++ string ++ "\x1b[39m";
}
pub fn red(comptime string: []const u8) []const u8 {
    return "\x1b[31m" ++ string ++ "\x1b[39m";
}

pub fn bold(comptime string: []const u8) []const u8 {
    return "\x1b[1m" ++ string ++ "\x1b[22m";
}
pub fn italic(comptime string: []const u8) []const u8 {
    return "\x1b[3m" ++ string ++ "\x1b[23m";
}
pub fn underline(comptime string: []const u8) []const u8 {
    return "\x1b[4m" ++ string ++ "\x1b[24m";
}
pub fn green(comptime string: []const u8) []const u8 {
    return "\x1b[32m" ++ string ++ "\x1b[39m";
}
pub fn yellow(comptime string: []const u8) []const u8 {
    return "\x1b[33m" ++ string ++ "\x1b[39m";
}
pub fn cyan(comptime string: []const u8) []const u8 {
    return "\x1b[36m" ++ string ++ "\x1b[39m";
}

test "simple test" {
    std.log.debug(red("ALERT"), .{});
    std.log.debug(magenta("Just kiddin', relax, it's all good"), .{});
}
