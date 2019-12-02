const std = @import("std");

const address_space = 65535;
const msize = u32;

fn load(file: std.fs.File, as: []msize) ![]msize {
    const stream = &file.inStream().stream;
    var buf: [20]u8 = undefined;
    var i: usize = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, ',')) |slice| {
        if (i == as.len) return error.NoSpace;
        as[i] = try std.fmt.parseInt(msize, std.mem.trim(u8, slice, "\n "), 10);
        i += 1;
    }
    return as[0..i];
}

fn step(as: []msize, pc: msize) !void {
    std.debug.assert(pc < as.len);
    switch(as[pc]) {
        1 => { // add
            as[as[pc+3]] = as[as[pc+1]] + as[as[pc+2]];
        },
        2 => { // multiply
            as[as[pc+3]] = as[as[pc+1]] * as[as[pc+2]];
        },
        99 => { // halt
            return error.Halt;
        },
        else => return error.UnknownOpcode,
    }
}

fn run(as: []msize) !void {
    var pc: msize = 0;
    while (true) : (pc += 4) {
        step(as, pc) catch |err| switch(err) {
            error.Halt => break,
            else => return err,
        };
    }
}

test "sample 1" {
    var as = [_]msize{1,9,10,3,2,3,11,0,99,30,40,50};
    try step(&as, 0);
    std.testing.expectEqualSlices(msize, &[_]msize{1,9,10,70,2,3,11,0,99,30,40,50}, &as);
    try step(&as, 4);
    std.testing.expectEqualSlices(msize, &[_]msize{3500,9,10,70,2,3,11,0,99,30,40,50}, &as);
    step(&as, 8) catch |err| switch(err) {
        error.Halt => {},
        else => return err,
    };
}

test "additional samples" {
    {
        var as = [_]msize{1,0,0,0,99};
        try run(&as);
        std.testing.expectEqualSlices(msize, &[_]msize{2,0,0,0,99}, &as);
    }
    {
        var as = [_]msize{2,3,0,3,99};
        try run(&as);
        std.testing.expectEqualSlices(msize, &[_]msize{2,3,0,6,99}, &as);
    }
    {
        var as = [_]msize{2,4,4,5,99,0};
        try run(&as);
        std.testing.expectEqualSlices(msize, &[_]msize{2,4,4,5,99,9801}, &as);
    }
    {
        var as = [_]msize{1,1,1,4,99,5,6,0,99};
        try run(&as);
        std.testing.expectEqualSlices(msize, &[_]msize{30,1,1,4,2,5,6,0,99}, &as);
    }
}

pub fn main() anyerror!void {
    var as: [address_space]msize = undefined;
    const mem = try load(std.io.getStdIn(), &as);
    // before running the program, replace position 1 with the value 12 and
    // replace position 2 with the value 2.
    mem[1] = 12;
    mem[2] = 2;
    try run(mem);
    try (&std.io.getStdOut().outStream().stream).print("Result: {}\n", as[0]);
}
