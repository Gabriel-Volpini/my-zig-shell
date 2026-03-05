const std = @import("std");
const Input = @import("input.zig").Input;

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

const Commands = enum {
    echo,
    type,
    notBuiltin,
    exit,
    pwd,

    pub fn getValue(str: []const u8) Commands {
        return std.meta.stringToEnum(Commands, str) orelse .notBuiltin;
    }

    pub fn getPath(allocator: std.mem.Allocator, cmd: []const u8) !?[]u8 {
        const path_env = std.posix.getenv("PATH") orelse return error.InvalidFilePath;
        var paths = std.mem.splitAny(u8, path_env, ":");

        while (paths.next()) |path| {
            const filePath = try std.fs.path.join(allocator, &.{ path, cmd });
            std.posix.access(filePath, std.posix.X_OK) catch {
                allocator.free(filePath);
                continue;
            };

            return filePath;
        } else {
            return null;
        }
    }
};

pub fn run(allocator: std.mem.Allocator, data: Input) void {
    const cmd = Commands.getValue(data.cmd);

    switch (cmd) {
        .echo => echo(data.args),
        .type => @"type"(allocator, data.args) catch {},
        .notBuiltin => notBuiltin(allocator, data),
        .exit => std.process.exit(0),
        .pwd => pwd(allocator),
    }
}

fn echo(args: [][]const u8) void {
    if (args.len <= 0) return;

    stdout.print("{s}\n", .{args[0]}) catch {};
}

fn @"type"(allocator: std.mem.Allocator, args: [][]const u8) !void {
    const strCommand = args[0];
    const cmd = Commands.getValue(strCommand);

    if (cmd != .notBuiltin) return try stdout.print("{s} is a shell builtin\n", .{strCommand});

    const filePath = try Commands.getPath(allocator, strCommand);

    if (filePath) |fp| {
        defer allocator.free(fp);
        try stdout.print("{s} is {s} \n", .{ strCommand, fp });
    } else {
        try stdout.print("{s}: not found\n", .{strCommand});
    }
}

fn notBuiltin(allocator: std.mem.Allocator, data: Input) void {
    const filePath = Commands.getPath(allocator, data.cmd) catch return;

    if (filePath) |fp| {
        defer allocator.free(fp);

        var argv: std.ArrayList([]const u8) = .empty;
        defer argv.deinit(allocator);

        argv.append(allocator, fp) catch return;
        argv.appendSlice(allocator, data.args) catch return;

        var child = std.process.Child.init(argv.items, allocator);
        child.stdin_behavior = .Inherit;
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;

        child.spawn() catch return;
        _ = child.wait() catch return;
    } else {
        stdout.print("{s}: command not found\n", .{data.cmd}) catch return;
    }
}

fn pwd(allocator: std.mem.Allocator) void {
    const cwd = std.process.getCwdAlloc(allocator) catch return;
    defer allocator.free(cwd);

    stdout.print("{s}\n", .{cwd}) catch return;
}
