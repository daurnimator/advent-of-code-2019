const std = @import("std");

const Direction = enum {
    Left,
    Right,
    Up,
    Down
};

const WireMovement = struct {
    dir: Direction,
    n: usize,
};

const ReadWireResult = struct {
    wm: WireMovement,
    is_last: bool,
};

fn readWireMovement(stream: var) !ReadWireResult {
    var char: [1]u8 = undefined;
    const amt_read = try stream.readFull(&char);

    const dir: Direction = switch(char[0]) {
        'L' => .Left,
        'R' => .Right,
        'U' => .Up,
        'D' => .Down,
        else => return error.InvalidDirection,
    };

    var buf: [20]u8 = undefined;
    var index: usize = 0;
    var is_last: bool = undefined;
    while (true) : (index += 1) {
        const byte = try stream.readByte();
        if (byte == ',' or byte == '\n') {
            is_last = byte == '\n';
            break;
        }
        if (index >= buf.len) return error.StreamTooLong;

        buf[index] = byte;
    }
    if (index == 0) return error.MissingDistance;
    const slice = buf[0..index];
    const n = try std.fmt.parseInt(usize, slice, 10);

    return ReadWireResult {
        .wm = WireMovement {
            .dir = dir,
            .n = n,
        },
        .is_last = is_last,
    };
}

const max_size = 65536;

pub fn main() anyerror!void {
    const file = std.io.getStdIn();
    const stream = &file.inStream().stream;

    // var grid = [_][max_size]bool{ [_]bool{false} ** max_size } ** max_size;
    var grid = try std.heap.direct_allocator.create([max_size][max_size]bool);
    defer std.heap.direct_allocator.destroy(grid);
    // direct allocator returns 0'd memory
    // @memset(@ptrCast([*]u8, grid), 0, max_size * max_size * @sizeOf(u32));

    var w1_movements = std.ArrayList(WireMovement).init(std.heap.direct_allocator);
    while (true) {
        const rwm = try readWireMovement(stream);
        const s = rwm.wm;
        std.debug.warn("1 {}\n", s);
        try w1_movements.append(s);
        if (rwm.is_last) break;
    }


    {
        var x: isize = 0;
        var y: isize = 0;
        for (w1_movements.toSliceConst()) |s| {
            var i: usize = 0;
            while (i < s.n) : (i += 1) {
                switch (s.dir) {
                    .Left => x -= 1,
                    .Right => x += 1,
                    .Up => y += 1,
                    .Down => y -= 1,
                }
                if (x < -(max_size/2) or @intCast(usize, x + (max_size/2)) >= grid.len or y < -(max_size/2) or @intCast(usize, y + (max_size/2)) >= grid[0].len) {
                    std.debug.warn("x={} y={}\n", x, y);
                    return error.OutOfBounds;
                }
                grid[@intCast(usize, x + (max_size/2))][@intCast(usize, y + (max_size/2))] = true;
            }
        }
    }

    var crossings = std.ArrayList(struct { x: isize, y: isize, w2: u32 }).init(std.heap.direct_allocator);

    {
        var x: isize = 0;
        var y: isize = 0;
        var steps_taken: u32 = 1;
        while (true) {
            const rwm = try readWireMovement(stream);
            const s = rwm.wm;
            std.debug.warn("2 {}\n", s);
            var i: usize = 0;
            while (i < s.n) : ({i += 1; steps_taken += 1;}) {
                switch (s.dir) {
                    .Left => x -= 1,
                    .Right => x += 1,
                    .Up => y += 1,
                    .Down => y -= 1,
                }
                if (x < -(max_size/2) or @intCast(usize, x + (max_size/2)) >= grid.len or y < -(max_size/2) or @intCast(usize, y + (max_size/2)) >= grid[0].len) return error.OutOfBounds;
                if (grid[@intCast(usize, x + (max_size/2))][@intCast(usize, y + (max_size/2))]) {
                    try crossings.append(.{
                        .x = x,
                        .y = y,
                        .w2 = steps_taken,
                    });
                }
            }
            if (rwm.is_last) break;
        }
    }


    var lowest_distance: ?usize = null;
    {
        var x: isize = 0;
        var y: isize = 0;
        var steps_taken: u32 = 1;
        for (w1_movements.toSliceConst()) |s| {
            var i: usize = 0;
            while (i < s.n) : ({i += 1; steps_taken += 1;}) {
                switch (s.dir) {
                    .Left => x -= 1,
                    .Right => x += 1,
                    .Up => y += 1,
                    .Down => y -= 1,
                }
                for (crossings.toSliceConst()) |c| {
                    if (c.x == x and c.y == y) {
                        const sum_steps = c.w2 + steps_taken;
                        std.debug.warn("found crossing: x={} y={} w1={} w2={} total={}\n", x, y, steps_taken, c.w2, sum_steps);
                        if (lowest_distance == null or sum_steps < lowest_distance.?) {
                            lowest_distance = sum_steps;
                        }
                        break;
                    }
                }
            }
        }
    }


    if (lowest_distance) |d| {
        try (&std.io.getStdOut().outStream().stream).print("Result: distance={}\n", d);
    } else {
        try (&std.io.getStdOut().outStream().stream).print("Result: no crossings\n");
    }
}
