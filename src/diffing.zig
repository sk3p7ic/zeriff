const std = @import("std");
const ArrayList = std.ArrayList;

pub const DiffAction = enum {
  ignore,
  add,
  remove,

  pub fn to_string(self: DiffAction) []u8 {
    return switch (self) {
      .ignore => " ",
      .add => "+",
      .remove => "-",
    };
  }
};

pub const DistanceResult = struct {
  action: DiffAction,
  location: usize,
  char: u8,
};

// This algo is from https://github.com/tsoding/piff/blob/master/piff.py (thanks tsoding)
pub fn calculate_distance(alloc: std.mem.Allocator, s1: []const u8, s2: []const u8) anyerror![]DistanceResult {
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
        if (s1[n1-1] == s2[n2-1]) {
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

  var patch = ArrayList(DistanceResult).init(alloc);
  defer patch.deinit();
  var n1 = m1 - 1;
  var n2 = m2 - 1;
  while (n1 > 0 or n2 > 0) {
    const action = actions.items[n1].items[n2];
    switch (action) {
      .add => {
        n2 -= 1;
        try patch.append(.{ .action = .add, .location = n2, .char = s2[n2]});
      },
      .remove => {
        n1 -= 1;
        try patch.append(.{ .action = .remove, .location = n1, .char = s1[n1]});
      },
      .ignore => {
        n1 -= 1;
        n2 -= 1;
      }
    }
  }
  return patch.toOwnedSlice();
}
