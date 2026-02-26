const std = @import("std");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

var buffer: [1024]u8 = undefined;
var stdin_reader = std.fs.File.stdin().readerStreaming(&buffer);
const stdin = &stdin_reader.interface;

const Command = enum {
    invalid,
    exit,
};

pub fn main() !void {
    while (true) {
        try stdout.print("$ ", .{});

        const input: []const u8 = stdin.takeDelimiter('\n') catch null orelse "";
        const cmd: Command = std.meta.stringToEnum(Command, input) orelse .invalid;

        switch (cmd) {
            .exit => std.process.exit(0),
            .invalid => try stdout.print("{s}: command not found\n", .{input}),
        }
    }
}
