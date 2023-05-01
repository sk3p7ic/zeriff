const std = @import("std");
const zap = @import("zap");

const diffing = @import("diffing.zig");
const argparse = @import("argparse.zig");

const allocator = std.heap.page_allocator;


pub fn main() !void {
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const arg_state: argparse.ArgumentState = argparse.parse_args(args) catch |err| {
        argparse.print_err(err);
        return err;
    };
    std.debug.print("{}\n", .{arg_state}); // TODO: Remove.
}
