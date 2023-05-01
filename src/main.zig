const std = @import("std");
const zap = @import("zap");

const diffing = @import("diffing.zig");
const argparse = @import("argparse.zig");

const allocator = std.heap.page_allocator;


pub fn main() !void {
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const arg_state: argparse.ArgumentState = try argparse.parse_args(args);
    std.debug.print("{}\n", .{arg_state}); // TODO: Remove.
    // TODO: Fix exit flow
    if (arg_state.then_exit) {
        if (args.len == 1) {
            std.os.exit(1);
        } else {
            std.os.exit(0);
        }
    }
}
