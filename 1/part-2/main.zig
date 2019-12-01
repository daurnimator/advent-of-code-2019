const std = @import("std");

// Specifically, to find the fuel required for a module,
// take its mass, divide by three, round down, and subtract 2.
fn fuel_required(mass: u64) u64 {
    if (mass < 6) return 0;
    return (mass / 3) - 2;
}

fn fuel_required_including_fuel(mass: u64) u64 {
    var fuel = fuel_required(mass);
    var additional = fuel;
    while (additional > 0) {
        additional = fuel_required(additional);
        fuel += additional;
    }
    return fuel;
}

pub fn main() anyerror!void {
    const file = std.io.getStdIn();
    const stream = &file.inStream().stream;
    var buf: [20]u8 = undefined;
    var sum: u64 = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const mass = try std.fmt.parseInt(u64, line, 10);
        sum += fuel_required_including_fuel(mass);
    }
    try (&std.io.getStdOut().outStream().stream).print("Result: {}\n", sum);
}
