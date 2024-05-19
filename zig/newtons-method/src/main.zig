const std = @import("std");

// Newtons method finds roots of functions, i. e. x value, for which f(x) == 0.
// It's an iterative algorithm starting a guess value of x0 and then calculates next values:
// x1 = x0 - f(x0) / f'(x0)
// Each iterations produces answers with increased accuracy.
//
// This can be used to solve multitude of problems, for example calculating square roots:
// sqrt(x) == a or x == a^2
// , then
// f(a) = a^2 - x
// when f(a) = 0, then a^2 == x
// f'(a) = 2a

fn sqrt(x: f32) f32 {
    var a = x;
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        a = a - (a * a - x) / (2 * a);
    }
    return a;
}

pub fn main() !void {
    const input: f32 = 121;
    const result = sqrt(input);
    std.log.debug("sqrt({d})={d}", .{ input, result });
}
