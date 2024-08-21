const std = @import("std");

const Foo = struct {
    id: u32,
    name: []const u8,
};

const Bar = struct {
    id: u32,
};

const Baz = struct {
    id: u32,
    age: u32,
};

pub fn main() !void {
    const count: usize = 10_000;
    var foos: [count]Foo = undefined;
    var bars: [count]Bar = undefined;
    var bazs: [count]Baz = undefined;

    var i: u32 = 0;
    while (i < count) : (i += 1) {
        foos[i] = .{ .id = i, .name = "hello" };
        bars[i] = .{ .id = i };
        bazs[i] = .{ .id = i, .age = i + 123 };
    }

    const iter_count: usize = 1000;
    i = 0;
    while (i < iter_count) : (i += 1) {
        for (&foos, &bars, &bazs) |*foo, *bar, *baz| {
            if (foo.id == baz.id) {
                baz.age += 1;
            }
            foo.id += 1;
            bar.id += 1;
            baz.id += 1;
        }
    }
}
