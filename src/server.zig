const std = @import("std");
const zap = @import("zap");

const diffing = @import("diffing.zig");

fn on_request(r: zap.SimpleRequest) void {
    if (r.path) |p| {
        if (routes.get(p)) |handler| {
            handler(r);
            return;
        }
    }

    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

fn parse_file(contents: []const u8) [][]const u8 {
    const terminated_contents: []const u8 = std.fmt.allocPrint(allocator, "{s}\n", .{ contents }) catch contents;
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var iter = std.mem.split(u8, terminated_contents, "\n");
    while (iter.next()) |line| {
        lines.append(line) catch continue;
    }

    const lines_arr: [][]const u8 = lines.toOwnedSlice() catch &.{};
    return lines_arr;
}

fn handle_api_request(r: zap.SimpleRequest) void {
    if (r.body) |b| hndl: {
        const InputData = struct {
            file1: []const u8 = "",
            file2: []const u8 = "",
        };

        const OutputData = struct {
            ok: bool,
            patch: []const diffing.SerializablePatchAction,
        };

        var stream = std.json.TokenStream.init(b);
        var data: InputData = undefined;
        if (std.json.parse(InputData, &stream, .{ .allocator = allocator })) |json| {
            data = json;
        } else |err| {
            std.debug.print("[!] {}\n", .{ err });
            break :hndl;
        }

        const f1 = parse_file(data.file1);
        const f2 = parse_file(data.file2);

        if (diffing.calculate_distance(allocator, f1, f2)) |patch| {
            var patches = std.ArrayList(diffing.SerializablePatchAction).init(allocator);
            defer patches.deinit();
            var i: usize = 0;
            while (i < patch.len): (i += 1) {
                const action = diffing.SerializablePatchAction {
                    .action = @tagName(patch[i].action),
                    .location = patch[i].location,
                    .line = patch[i].line,
                };
                patches.append(action) catch {};
            }
            const output = OutputData { .ok = true, .patch = patches.items };
            var string = std.ArrayList(u8).init(allocator);
            defer string.deinit();
            std.json.stringify(output, .{}, string.writer()) catch {};
            r.sendJson(string.items) catch return;
            return;
        } else |err| {
            std.debug.print("[!] {}\n", .{ err });
            break :hndl;
        }
    }
    std.debug.print("No body recieved.\n", .{});
    r.sendJson(
        \\{"ok": "false"}
    ) catch return;
}

fn setup_routes(alloc: std.mem.Allocator) !void {
    allocator = alloc;
    routes = std.StringHashMap(zap.SimpleHttpRequestFn).init(allocator);
    try routes.put("/api", handle_api_request);
}

var allocator: std.mem.Allocator = undefined;
var routes: std.StringHashMap(zap.SimpleHttpRequestFn) = undefined;

pub fn start(alloc: std.mem.Allocator, port: u16, num_threads: u8, num_workers: u8) !void {
    try setup_routes(alloc);
    var listener = zap.SimpleHttpListener.init(.{
        .port = port,
        .on_request = on_request,
        .log = true,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:{d}...\n", .{ port });

    // Start worker threads
    zap.start(.{
        .threads = num_threads,
        .workers = num_workers,
    });
}
