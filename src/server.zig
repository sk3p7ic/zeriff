const std = @import("std");
const zap = @import("zap");

fn on_request(r: zap.SimpleRequest) void {
    if (r.path) |p| {
        if (routes.get(p)) |handler| {
            handler(r);
            return;
        }
    }

    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

fn handle_api_request(r: zap.SimpleRequest) void {
    if (r.body) |bod| {
        std.debug.print("Data: {s}\n", .{ bod });
    }
    r.sendJson(
        \\{"stat": "ok"}
    ) catch return;
}

fn setup_routes(alloc: std.mem.Allocator) !void {
    routes = std.StringHashMap(zap.SimpleHttpRequestFn).init(alloc);
    try routes.put("/api", handle_api_request);
}

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
