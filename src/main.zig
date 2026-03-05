const std = @import("std");
const Input = @import("input.zig").Input;
const Command = @import("command.zig");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

var buffer: [1024]u8 = undefined;
var stdin_reader = std.fs.File.stdin().readerStreaming(&buffer);
const stdin = &stdin_reader.interface;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    while (true) {
        try stdout.print("$ ", .{});

        const input: []const u8 = stdin.takeDelimiter('\n') catch "" orelse "";
        const parsedInput = try Input.parse(allocator, input);

        Command.run(allocator, parsedInput);
    }
}
