const std = @import("std");

const FooId = enum(usize) { _ };
test FooId {
    const some_usize: usize = 123;
    const foo_id: FooId = @enumFromInt(some_usize);
    _ = foo_id;
}

const BarId = usize;
const BazId = usize;
test BarId {
    const some_usize: usize = 123;
    const bar_id: BarId = some_usize; // Not very strong.
    const baz_id: BazId = bar_id; // Indeed.
    _ = baz_id;
}
