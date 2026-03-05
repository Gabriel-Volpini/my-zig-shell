const std = @import("std");
const command = @import("commands/main.zig").Command;

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

var buffer: [1024]u8 = undefined;
var stdin_reader = std.fs.File.stdin().readerStreaming(&buffer);
const stdin = &stdin_reader.interface;

const Command = enum {
    echo,
    exit,
    external,
    type,

    pub fn transform(str: []const u8) ?Command {
        return std.meta.stringToEnum(Command, str);
    }

    pub fn isBuiltin(str: []const u8) bool {
        const value = Command.transform(str);
        return if (value != null) true else false;
    }

    pub fn getPath(allocator: std.mem.Allocator, cmd: []const u8) !?[]u8 {
        const path_env = std.posix.getenv("PATH") orelse return error.InvalidFilePath;
        var paths = std.mem.splitAny(u8, path_env, ":");

        while (paths.next()) |path| {
            const filePath = try std.fmt.allocPrint(
                allocator,
                "{s}/{s}",
                .{ path, cmd },
            );
            std.posix.access(filePath, std.posix.X_OK) catch continue;

            return filePath;
        } else {
            return null;
        }
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    while (true) {
        try stdout.print("$ ", .{});

        const input: []const u8 = stdin.takeDelimiter('\n') catch null orelse "";
        // var inputIterator = std.mem.splitAny(u8, input, " ");

        // const cmd: Command = Command.transform(inputIterator.next().?) orelse .external;
        // const arg: []const u8 = inputIterator.rest();

        // switch (cmd) {
        //     .echo => try stdout.print("{s}\n", .{arg}),
        //     .exit => std.process.exit(0),
        //     .external => try handleExternal(allocator, input),
        //     .type => try handleType(allocator, arg),
        // }
    }
}

fn handleType(allocator: std.mem.Allocator, cmd: []const u8) !void {
    if (Command.isBuiltin(cmd)) return try stdout.print("{s} is a shell builtin\n", .{cmd});

    const filePath = try Command.getPath(allocator, cmd);

    if (filePath) |fp| {
        try stdout.print("{s} is {s} \n", .{ cmd, fp });
    } else {
        try stdout.print("{s}: not found\n", .{cmd});
    }
}

fn handleExternal(allocator: std.mem.Allocator, input: []const u8) !void {
    var inputIterator = std.mem.splitAny(u8, input, " ");
    const cmd = inputIterator.first();

    const filePath = try Command.getPath(allocator, cmd);

    if (filePath != null) {
        var args = std.ArrayList([]const u8){};
        defer args.deinit(allocator);

        try args.append(allocator, cmd);

        while (inputIterator.next()) |v| {
            try args.append(allocator, v);
        }

        var child = std.process.Child.init(args.items, allocator);
        child.stdin_behavior = .Inherit;
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;

        try child.spawn();
        _ = try child.wait();
    } else {
        try stdout.print("{s}: command not found\n", .{input});
    }
}
