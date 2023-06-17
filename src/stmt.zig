const std = @import("std");
const mem = std.mem;
const exp = @import("./expr.zig");

const Allocator = mem.Allocator;
const Expr = exp.Expr;

pub const Type = union(TypeKind) {
    Int,
    UserDefined: []const u8,
};

pub const TypeKind = enum {
    Int,
    UserDefined,
};

pub const Stmt = union(StmtKind) {
    const Self = @This();

    LetBindingStmt: LetBinding,

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.LetBindingStmt.deinit(allocator);
    }
};

pub const StmtKind = enum {
    LetBindingStmt,
};

pub const LetBinding = struct {
    const Self = @This();

    id: []const u8,
    type: Type,
    expr: Expr,

    pub fn deinit(self: *Self, allocator: Allocator) void {
        self.expr.deinit(allocator);
    }
};
