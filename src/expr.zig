const std = @import("std");
const tok = @import("./token.zig");

const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

const Token = tok.Token;
const TokenKind = tok.TokenKind;

pub const Expr = union(ExprKind) {
    const Self = @This();

    ValueExpr: Value,
    BinaryExpr: *Binary,
    FnCallExpr: *FnCall,

    pub fn deinit(self: *Self, allocator: Allocator) void {
        switch (self.*) {
            .BinaryExpr => {
                self.BinaryExpr.lhs.deinit(allocator);
                self.BinaryExpr.rhs.deinit(allocator);
                allocator.destroy(self.BinaryExpr);
            },
            .FnCallExpr => {
                for (self.FnCallExpr.arguments.items) |*item| {
                    item.deinit(allocator);
                }

                self.FnCallExpr.arguments.deinit();
            },
            else => return,
        }
    }
};

pub const ExprKind = enum {
    ValueExpr,
    BinaryExpr,
    FnCallExpr,
};

pub const Binary = struct {
    op: BinaryOp,
    lhs: Expr,
    rhs: Expr,
};

pub const BinaryOp = enum {
    const Self = @This();

    Add,
    Sub,
    Mul,
    Div,
    Mod,

    pub fn from_token(kind: TokenKind) ?Self {
        return switch (kind) {
            .Plus => .Add,
            .Minus => .Sub,
            .Star => .Mul,
            .Slash => .Div,
            .Percent => .Mod,
            else => null,
        };
    }
};

pub const Value = union(ValueKind) {
    IntLiteral: i64,
    Identifier: []const u8,
};

pub const ValueKind = enum {
    IntLiteral,
    Identifier,
};

pub const FnCall = struct {
    id: []const u8,
    arguments: ArrayList(Expr),
};
