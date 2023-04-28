const std = @import("std");
const ArrayList = std.ArrayList;

pub const DiffAction = enum {
  ignore,
  add,
  remove,

  pub fn to_string(self: DiffAction) []const u8 {
    return switch (self) {
      .ignore => " ",
      .add => "+",
      .remove => "-",
    };
  }
};

pub const PatchAction = struct {
  action: DiffAction,
  location: usize,
  line: []const u8,

  pub fn to_string(self: PatchAction, alloc: std.mem.Allocator) []u8 {
    if (std.fmt.allocPrint(alloc, "{d} {s} {s}", .{ self.location, self.action.to_string(), self.line })) |s| {
      return s;
    } else |_| {
      return "";
    }
  }
};

// This algo is from https://github.com/tsoding/piff/blob/master/piff.py (thanks tsoding)
pub fn calculate_distance(alloc: std.mem.Allocator, s1: [][]const u8, s2: [][]const u8) anyerror![]PatchAction {
  const m1: usize = s1.len;
  const m2: usize = s2.len;

  var distances = ArrayList(ArrayList(u16)).init(alloc);
  defer distances.deinit();
  var actions = ArrayList(ArrayList(DiffAction)).init(alloc);
  defer actions.deinit();


  var i: usize = 0;
  while (i < m1 + 1): (i += 1) {
    var dist_row = ArrayList(u16).init(alloc);
    try dist_row.appendNTimes(0, m2);
    var act_row = ArrayList(DiffAction).init(alloc);
    try act_row.appendNTimes(.ignore, m2);
    try distances.append(dist_row);
    try actions.append(act_row);
  }

  distances.items[0].items[0] = 0;
  actions.items[0].items[0] = .ignore;

  {
    var n2: u16 = 1;
    while (n2 < m2): (n2 += 1) {
      const n1 = comptime 0;
      distances.items[n1].items[n2] = n2;
      actions.items[n1].items[n2] = .add;
    }
  }

  {
    var n1: u16 = 1;
    while (n1 < m1): (n1 += 1) {
      const n2 = comptime 0;
      distances.items[n1].items[n2] = n1;
      actions.items[n1].items[n2] = .remove;
    }
  }

  {
    var n1: u16 = 1;
    while (n1 < m1): (n1 += 1) {
      var n2: u16 = 1;
      while (n2 < m2): (n2 += 1) {
        if (lines_are_equal(s1[n1-1], s2[n2-1])) {
          distances.items[n1].items[n2] = distances.items[n1-1].items[n2-1];
          actions.items[n1].items[n2] = .ignore;
          continue;
        }

        const remove = distances.items[n1-1].items[n2];
        const add = distances.items[n1].items[n2-1];

        distances.items[n1].items[n2] = remove;
        actions.items[n1].items[n2] = .remove;

        if (distances.items[n1].items[n2] > add) {
          distances.items[n1].items[n2] = add;
          actions.items[n1].items[n2] = .add;
        }
        
        distances.items[n1].items[n2] += 1;
      }
    }
  }

  var patch = ArrayList(PatchAction).init(alloc);
  defer patch.deinit();
  var n1 = m1 - 1;
  var n2 = m2 - 1;
  while (n1 > 0 or n2 > 0) {
    const action = actions.items[n1].items[n2];
    switch (action) {
      .add => {
        n2 -= 1;
        try patch.append(.{ .action = .add, .location = n2, .line = s2[n2]});
      },
      .remove => {
        n1 -= 1;
        try patch.append(.{ .action = .remove, .location = n1, .line = s1[n1]});
      },
      .ignore => {
        n1 -= 1;
        n2 -= 1;
      }
    }
  }
  // Deinit memory in the distances and actions ArrayLists
  for (distances.items) |item| {
    item.deinit();
  }
  for (actions.items) |item| {
    item.deinit();
  }

  return patch.toOwnedSlice();
}

fn lines_are_equal(line1: []const u8, line2: []const u8) bool {
  if (line1.len != line2.len) {
    return false;
  }

  var i: usize = 0;
  while (i < line1.len): (i+=1) {
    if (line1[i] != line2[i]) {
      return false;
    }
  }
  return true;
}

test "proper diffing" {
  const ts1 =
    \\Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
    \\incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
    \\nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
    \\Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
    \\eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident,
    \\sunt in culpa qui officia deserunt mollit anim id est laborum.
  ;
  const ts2 =
    \\Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
    \\incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
    \\nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
    \\Duis aute irure in dolor reprehenderit in voluptate velit esse cillum dolore
    \\eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident,
    \\sunt in culpa qui officia deserunt mollit anim id est laborum.
  ;

  const alloc = std.testing.allocator;
  var s1 = ArrayList([]const u8).init(alloc);
  defer s1.deinit();
  var s2 = ArrayList([]const u8).init(alloc);
  defer s2.deinit();

  var iter1 = std.mem.split(u8, ts1, "\n");
  var iter2 = std.mem.split(u8, ts2, "\n");

  while (iter1.next()) |line| {
    try s1.append(line);
  }
  while (iter2.next()) |line| {
    try s2.append(line);
  }

  const p = try calculate_distance(alloc, s1.items, s2.items);
  const expect = std.testing.expect;
  try expect(p.len == 2);
  try expect(p[0].action == DiffAction.remove);
  std.debug.print("Patch[0]: {s}\nPatch[1]: {s}\n", .{ p[0].to_string(alloc), p[1].to_string(alloc) });
}
