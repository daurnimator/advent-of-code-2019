const std = @import("std");

/// Two adjacent digits are the same (like 22 in 122345).
fn equalAdjacentDigits(digits: [6]u8) bool {
    for (digits[1..]) |y, j| {
        const x = digits[j];
        if (x == y) {
            return true;
        }
    }
    return false;
}

/// Going from left to right, the digits never decrease;
/// they only ever increase or stay the same (like 111123 or 135679).
fn increasingDigits(digits: [6]u8) bool {
    for (digits[1..]) |y, j| {
        const x = digits[j];
        if (x > y) {
            return false;
        }
    }
    return true;
}

pub fn main() anyerror!void {
    var args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    const range_start = try std.fmt.parseInt(u32, args[1], 10);
    const range_end = try std.fmt.parseInt(u32, args[2], 10);

    var i = range_start;
    var n: u32 = 0;
    while (i <= range_end) : (i += 1) {
        const digits = [6]u8{
            @intCast(u8, i / 100000 % 10),
            @intCast(u8, i / 10000 % 10),
            @intCast(u8, i / 1000 % 10),
            @intCast(u8, i / 100 % 10),
            @intCast(u8, i / 10 % 10),
            @intCast(u8, i % 10),
        };

        if (!increasingDigits(digits)) continue;

        if (!equalAdjacentDigits(digits)) continue;

        // try (&std.io.getStdOut().outStream().stream).print("n={}{}{}{}{}{}\n", digits[0], digits[1], digits[2], digits[3], digits[4], digits[5]);
        n += 1;
    }

    try (&std.io.getStdOut().outStream().stream).print("Result: {}-{}. Potential passwords: {}\n", range_start, range_end, n);
}
