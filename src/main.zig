const std = @import("std");
const tok = @import("./token.zig");
const Parser = @import("./parser.zig");

const AutoHashMap = std.AutoHashMap;
const Token = tok.Token;
const TokenKind = tok.TokenKind;

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
    try parser.parse_whole();
}
