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

    pub fn transform(str: []const u8) ?Command {
        return std.meta.stringToEnum(Command, str);
    }

    pub fn isBuiltin(str: []const u8) bool {
        const value = Command.transform(str);
        return if (value != null) true else false;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    while (true) {
        try stdout.print("$ ", .{});

        const input: []const u8 = stdin.takeDelimiter('\n') catch null orelse "";
        var inputIterator = std.mem.splitAny(u8, input, " ");

        const cmd: Command = Command.transform(inputIterator.next().?) orelse .invalid;
        const arg: []const u8 = inputIterator.rest();

        switch (cmd) {
            .echo => try stdout.print("{s}\n", .{arg}),
            .exit => std.process.exit(0),
            .invalid => try stdout.print("{s}: command not found\n", .{input}),
            .type => try handleType(allocator, arg),
        }
    }
}

fn handleType(allocator: std.mem.Allocator, cmd: []const u8) !void {
    if (Command.isBuiltin(cmd)) return try stdout.print("{s} is a shell builtin\n", .{cmd});

    const path_env = std.posix.getenv("PATH") orelse return;
    var paths = std.mem.splitAny(u8, path_env, ":");

    while (paths.next()) |path| {
        const filePath = try std.fmt.allocPrint(
            allocator,
            "{s}/{s}",
            .{ path, cmd },
        );
        std.posix.access(filePath, std.posix.X_OK) catch continue;

        try stdout.print("{s} is {s} \n", .{ cmd, filePath });
    }
}
