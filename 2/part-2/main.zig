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

const NounVerb = struct {
    noun: msize,
    verb: msize,
};

fn find(input: []const msize, target: msize) !NounVerb {
    // The inputs should still be provided to the program by replacing the values at addresses 1 and 2,
    // just like before. In this program, the value placed in address 1 is called the noun,
    // and the value placed in address 2 is called the verb. Each of the two input values will be
    // between 0 and 99, inclusive.
    var noun: msize = 0;
    var verb: msize = undefined;
    while (noun <= 99) : (noun += 1) {
        verb = 0;
        while (verb <= 99) : (verb += 1) {
            var as: [address_space]msize = undefined;
            const mem = as[0..input.len];
            std.mem.copy(msize, mem, input);
            mem[1] = noun;
            mem[2] = verb;
            try run(mem);
            if (mem[0] == target) return NounVerb {
                .noun = noun,
                .verb = verb,
            };
        }
    }
    return error.NotFound;
}
pub fn main() anyerror!void {
    var as: [address_space]msize = undefined;
    const input = try load(std.io.getStdIn(), &as);
    const result = try find(input, 19690720);
    try (&std.io.getStdOut().outStream().stream).print("Noun: {} Verb: {}\n", result.noun, result.verb);
}
