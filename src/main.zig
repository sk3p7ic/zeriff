const std = @import("std");
const zap = @import("zap");

const diffing = @import("diffing.zig");
const argparse = @import("argparse.zig");

const allocator = std.heap.page_allocator;

fn diff_files(fname1: []const u8, fname2: []const u8) !u8 {
    std.debug.print("{s} {s}\n", .{ fname1, fname2 });
    return 0;
}

fn start_server() !u8 {
    std.debug.print("Starting server.\n", .{});
    return 0;
}

pub fn main() !void {
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var arg_state = argparse.ArgumentState{ .mode = argparse.ProgramMode.unset };
    if (argparse.parse_args(args)) |state| {
        arg_state = state;
        if (arg_state.mode == argparse.ProgramMode.unset) {
            std.os.exit(0);
        }
    } else |err| {
        _ = argparse.print_err(err);
        std.os.exit(1);
    }
    std.debug.print("{}\n", .{arg_state}); // TODO: Remove.
    if (arg_state.mode == argparse.ProgramMode.diff) {
        const status = try diff_files(arg_state.df_one, arg_state.df_two);
        std.os.exit(status);
    } else if (arg_state.mode == argparse.ProgramMode.serve) {
        const status = try start_server();
        std.os.exit(status);
    }
}
