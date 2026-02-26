const std = @import("std");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

var buffer: [1024]u8 = undefined;
var stdin_reader = std.fs.File.stdin().readerStreaming(&buffer);
const stdin = &stdin_reader.interface;

pub fn main() !void {
    try stdout.print("$ ", .{});

    const command: []const u8 = stdin.takeDelimiter('\n') orelse "";

    try stdout.print("{s}: command not found\n", .{command});
}
