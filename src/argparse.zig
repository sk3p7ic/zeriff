const std = @import("std");

pub const ProgramMode = enum {
    diff,
    serve,
    unset,
    erroneous,
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
    UnknownArgument,
};

pub fn print_err(err: ArgParseErr) ArgumentState {
    const stderr = std.io.getStdErr();
    switch (err) {
        ArgParseErr.NoArgumentsSupplied => {
            stderr.writeAll("[!] No arguments were supplied.\n\n") catch {};
            ArgumentState.print_help();
            return ArgumentState{ .mode = ProgramMode.erroneous };
        },
        ArgParseErr.NotEnoughArguments => {
            stderr.writeAll("[!] Not enough arguments were supplied.\n\n") catch {};
            ArgumentState.print_help();
            return ArgumentState{ .mode = ProgramMode.erroneous };
        },
        ArgParseErr.DualModeAttempted => {
            stderr.writeAll("[!] Two modes were attempted to be used. This is illegal!\n\n") catch {};
            ArgumentState.print_help();
            return ArgumentState{ .mode = ProgramMode.erroneous };
        },
        ArgParseErr.UnknownArgument => {
            stderr.writeAll("[!] Uknown argument.\n\n") catch {};
            ArgumentState.print_help();
            return ArgumentState{ .mode = ProgramMode.erroneous };
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
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        std.debug.print("Checking: {s}\n", .{ args[i] });
        if (iter_skip != 0) {
            std.debug.print("Skipping: {s}\n", .{ args[i] });
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
            if (i + 1 != args.len) {
                state.serve_port = std.fmt.parseUnsigned(u16, args[i + 1], 10) catch blk: {
                    std.io.getStdErr().writeAll("[!] Invalid argument.\n\n") catch {};
                    break :blk 5173;
                };
                iter_skip = 1;
            }
        } else {
            return ArgParseErr.UnknownArgument;
        }
    }

    return state;
}
