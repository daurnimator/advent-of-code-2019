const std = @import("std");

// Specifically, to find the fuel required for a module,
// take its mass, divide by three, round down, and subtract 2.
fn fuel_required(mass: u64) u64 {
    return (mass / 3) - 2;
}

pub fn main() anyerror!void {
    const file = std.io.getStdIn();
    const stream = &file.inStream().stream;
    var buf: [20]u8 = undefined;
    var sum: u64 = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const mass = try std.fmt.parseInt(u64, line, 10);
        sum += fuel_required(mass);
    }
    try (&std.io.getStdOut().outStream().stream).print("Result: {}\n", sum);
}
