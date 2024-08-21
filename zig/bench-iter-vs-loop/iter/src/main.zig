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

const IterItem = struct {
    foo: *Foo,
    bar: *Bar,
    baz: *Baz,
};

const Iter = struct {
    foos: []Foo,
    bars: []Bar,
    bazs: []Baz,
    foo_index: usize = 0,
    bar_index: usize = 0,
    baz_index: usize = 0,

    pub fn init(foos: []Foo, bars: []Bar, bazs: []Baz) Iter {
        return .{ .foos = foos, .bars = bars, .bazs = bazs };
    }

    pub fn next(self: *@This()) ?IterItem {
        if (self.foo_index < self.foos.len and
            self.bar_index < self.bars.len and
            self.baz_index < self.bazs.len)
        {
            const item: IterItem = .{
                .foo = &self.foos[self.foo_index],
                .bar = &self.bars[self.bar_index],
                .baz = &self.bazs[self.baz_index],
            };
            self.foo_index += 1;
            self.bar_index += 1;
            self.baz_index += 1;
            return item;
        } else {
            return null;
        }
    }
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
        var iter = Iter.init(&foos, &bars, &bazs);
        while (iter.next()) |item| {
            if (item.foo.id == item.baz.id) {
                item.baz.age += 1;
            }
            item.foo.id += 1;
            item.bar.id += 1;
            item.baz.id += 1;
        }
    }

    for (bazs) |baz| {
        std.debug.print("baz id={d} age={d}\n", .{ baz.id, baz.age });
    }
}
