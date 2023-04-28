const std = @import("std");
const zap = @import("zap");

const diffing = @import("diffing.zig");

pub fn main() !void {
  const allocator = std.heap.page_allocator;

  _ = try diffing.calculate_distance(allocator, "Foo", "Bar");
}

