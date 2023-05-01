const std = @import("std");

pub const ProgramMode = enum {
    diff,
    serve,
    unset,
};

pub const ArgumentState = struct {
    mode: ProgramMode = ProgramMode.unset,
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

pub const ArgParseErr = error{
    NoArgumentsSupplied,
    NotEnoughArguments,
    DualModeAttempted,
};

pub fn print_err(err: ArgParseErr) void {
    const stderr = std.io.getStdErr();
    switch (err) {
        ArgParseErr.NoArgumentsSupplied => {
            stderr.writeAll("[!] No arguments were supplied.\n\n") catch {};
            ArgumentState.print_help();
            std.os.exit(1);
        },
        ArgParseErr.NotEnoughArguments => {
            stderr.writeAll("[!] Not enough arguments were supplied.\n\n") catch {};
            ArgumentState.print_help();
            std.os.exit(1);
        },
        ArgParseErr.DualModeAttempted => {
            stderr.writeAll("[!] Two modes were attempted to be used. This is illegal!\n\n") catch {};
            ArgumentState.print_help();
            std.os.exit(1);
        }
    }
}

pub fn parse_args(args: []const []const u8) ArgParseErr!ArgumentState {
    if (args.len == 1) {
        return ArgParseErr.NoArgumentsSupplied;
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
            return ArgumentState{};
        } else if (s_cmp(u8, arg, "diff")) {
            if (i + 1 == args.len or i + 2 == args.len) {
                return ArgParseErr.NotEnoughArguments;
            }
            if (state.mode != ProgramMode.unset) {
                return ArgParseErr.DualModeAttempted;
            }
            state.mode = ProgramMode.diff;
            state.df_one = args[i + 1];
            state.df_two = args[i + 2];
            iter_skip = 2;
        } else if (s_cmp(u8, arg, "serve")) {
            if (state.mode != ProgramMode.unset) {
                return ArgParseErr.DualModeAttempted;
            }
            state.mode = ProgramMode.serve;
            if (i + 1 == args.len) {
                return ArgParseErr.NotEnoughArguments;
            }
            state.serve_port = std.fmt.parseUnsigned(u16, args[i + 1], 10) catch blk: {
                std.io.getStdErr().writeAll("[!] Invalid argument.\n\n") catch {};
                break :blk 5173;
            };
        }
    }
    // TODO: Check that diff and serve mode are not both active

    return state;
}
