const std = @import("std");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

var buffer: [1024]u8 = undefined;
var stdin_reader = std.fs.File.stdin().readerStreaming(&buffer);
const stdin = &stdin_reader.interface;

const Command = enum {
    echo,
    exit,
    invalid,
    type,
};

pub fn main() !void {
    while (true) {
        try stdout.print("$ ", .{});

        const input: []const u8 = stdin.takeDelimiter('\n') catch null orelse "";
        var inputIterator = std.mem.splitAny(u8, input, " ");

        const cmd: Command = std.meta.stringToEnum(Command, inputIterator.next().?) orelse .invalid;
        const arg: []const u8 = inputIterator.rest();

        switch (cmd) {
            .echo => try stdout.print("{s}\n", .{arg}),
            .exit => std.process.exit(0),
            .invalid => try stdout.print("{s}: command not found\n", .{input}),
            .type => if (std.meta.stringToEnum(Command, arg) != null) try stdout.print("{s} is a shell builtin\n", .{arg}) else try stdout.print("{s}: not found\n", .{arg}),
        }
    }
}
