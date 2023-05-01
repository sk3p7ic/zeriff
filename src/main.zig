const std = @import("std");
const zap = @import("zap");

const diffing = @import("diffing.zig");

const allocator = std.heap.page_allocator;

const ArgumentState = struct {
    then_exit: bool = false,
    serve_mode: bool = false,
    serve_port: u16 = 5173,
    df_one: []const u8 = "",
    df_two: []const u8 = "",

    pub fn print_help() void {
        const help_string =
            \\Usage: zeriff [command] [options]
            \\ 
            \\Commands:
            \\
            \\  diff  <file1> <file2>        Get the diff between two files, from file1 to file2.
            \\  serve [port]                 Start the web server with a given port number (default=5173).
            \\
            \\General Options:
            \\
            \\  -h, --help                   Print this help and exit.
            \\
        ;
        std.io.getStdOut().writeAll(help_string) catch {};
    }
};

fn parse_args(args: []const []const u8) error{NoArgumentsSupplied}!ArgumentState {
    if (args.len == 1) {
        ArgumentState.print_help();
        return ArgumentState{ .then_exit = true };
    }

    const s_cmp = std.mem.eql;

    var state = ArgumentState{};
    var iter_skip: u8 = 0; // Used to skip an interation, if needed
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        if (iter_skip != 0) {
            iter_skip -= 1;
            continue;
        }
        const arg: []const u8 = args[i];
        if (s_cmp(u8, arg, "-h") or s_cmp(u8, arg, "--help")) {
            ArgumentState.print_help();
            state.then_exit = true;
        } else if (s_cmp(u8, arg, "diff")) {
            if (i + 1 == args.len or i + 2 == args.len) {
                std.io.getStdErr().writeAll("[!] Error! Not enough arguments supplied!\n") catch {};
                ArgumentState.print_help();
                state.then_exit = true;
                std.os.exit(1);
            }
            state.df_one = args[i + 1];
            state.df_two = args[i + 2];
            iter_skip = 2;
        } else if (s_cmp(u8, arg, "serve")) {
            state.serve_mode = true;
            // TODO: Get port, if supplied
        }
    }
    // TODO: Check that diff and serve mode are not both active

    return state;
}

pub fn main() !void {
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const arg_state: ArgumentState = try parse_args(args);
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
