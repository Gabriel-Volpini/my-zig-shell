const std = @import("std");

pub const Input = struct {
    cmd: []const u8,
    args: [][]const u8,

    pub fn parse(allocator: std.mem.Allocator, data: []const u8) !Input {
        var inputIterator = std.mem.splitAny(u8, data, " ");
        const cmd = inputIterator.first();
        var args: std.ArrayList([]const u8) = .empty;
        defer args.deinit(allocator);

        while (inputIterator.next()) |i| {
            args.append(allocator, i) catch continue;
        }

        return .{
            .cmd = cmd,
            .args = try args.toOwnedSlice(allocator),
        };
    }
};
