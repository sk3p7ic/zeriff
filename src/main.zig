const std = @import("std");
const zap = @import("zap");

const diffing = @import("diffing.zig");
const argparse = @import("argparse.zig");

const allocator = std.heap.page_allocator;

fn read_file(fname: []const u8) ![][]const u8 {
    var file = try std.fs.cwd().openFile(fname, .{});
    const size_lim = std.math.maxInt(u32);
    var result = try file.readToEndAlloc(allocator, size_lim);
    var iter = std.mem.split(u8, result, "\n");

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    while (iter.next()) |line| {
        try lines.append(line);
    }

    return lines.toOwnedSlice();
}

fn diff_files(fname1: []const u8, fname2: []const u8) !u8 {
    const f1 = try read_file(fname1);
    const f2 = try read_file(fname2);

    const patch = try diffing.calculate_distance(allocator, f1, f2);
    const stdout = std.io.getStdOut();
    var i: usize = 0;
    while (i < patch.len): (i += 1) {
        const formatted_line = patch[i].to_string(allocator);
        stdout.writeAll(formatted_line) catch {};
    }


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
    if (arg_state.mode == argparse.ProgramMode.diff) {
        const status = try diff_files(arg_state.df_one, arg_state.df_two);
        std.os.exit(status);
    } else if (arg_state.mode == argparse.ProgramMode.serve) {
        const status = try start_server();
        std.os.exit(status);
    }
}
