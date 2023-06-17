const std = @import("std");
const tok = @import("./token.zig");
const exp = @import("./expr.zig");

const Parser = @import("./parser.zig");
const AutoHashMap = std.AutoHashMap;
const Token = tok.Token;
const TokenKind = tok.TokenKind;
const Expr = exp.Expr;

fn visit_expr(expr: Expr) void {
    switch (expr) {
        .ValueExpr => |value| {
            switch (value) {
                .IntLiteral => |il| std.debug.print("Value: {d}\n", .{il}),
                .Identifier => |id| std.debug.print("Value: {s}\n", .{id}),
            }
        },
        .BinaryExpr => |bin| {
            visit_expr(bin.lhs);
            std.debug.print("Op: {any}\n", .{bin.op});
            visit_expr(bin.rhs);
        },
        .FnCallExpr => |fncall| {
            std.debug.print("Id: {s}\n", .{fncall.id});
            for (fncall.arguments.items) |argument| {
                visit_expr(argument);
            }
        },
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var expr_prec = std.AutoHashMap(TokenKind, u8).init(allocator);
    defer expr_prec.deinit();

    try expr_prec.put(.Identifier, 0);
    try expr_prec.put(.IntLiteral, 0);
    try expr_prec.put(.Plus, 1);
    try expr_prec.put(.Minus, 1);
    try expr_prec.put(.Star, 2);
    try expr_prec.put(.Slash, 2);
    try expr_prec.put(.Percent, 2);

    var buffer: [1000]u8 = undefined;
    const input = try std.fs.cwd().readFile("test.fb", &buffer);

    var parser = Parser.init(input, expr_prec);
    try parser.parse_whole(allocator);
}
