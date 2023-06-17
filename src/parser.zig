const std = @import("std");
const tok = @import("./token.zig");
const exp = @import("./expr.zig");
const stm = @import("./stmt.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Lexer = @import("./lexer.zig");
const AutoHashMap = std.AutoHashMap;
const Token = tok.Token;
const TokenKind = tok.TokenKind;
const Expr = exp.Expr;
const ExprKind = exp.ExprKind;
const Binary = exp.Binary;
const BinaryOp = exp.BinaryOp;
const Value = exp.Value;
const ValueKind = exp.ValueKind;
const FnCall = exp.FnCall;
const Stmt = stm.Stmt;
const StmtKind = stm.StmtKind;
const Type = stm.Type;
const TypeKind = stm.TypeKind;
const LetBinding = stm.LetBinding;

pub const ParserError = error{
    SyntaxError,
};

const Self = @This();

lexer: Lexer,
token: Token,
expr_prec: AutoHashMap(TokenKind, u8),

fn eof(self: *const Self) bool {
    return self.token == TokenKind.EndOfFile;
}

fn expect(self: *const Self, kind: TokenKind) bool {
    return self.token == kind;
}

pub fn advance(self: *Self) void {
    self.token = self.lexer.get_token();
}

fn skip_whitespaces(self: *Self) void {
    while (!self.eof() and self.expect(TokenKind.Newline)) {
        self.advance();
    }
}

fn match(self: *Self, kind: TokenKind) !void {
    if (!self.expect(kind)) {
        return ParserError.SyntaxError;
    }

    self.advance();
}

fn parse_prim_expr(self: *Self, allocator: Allocator) error{ SyntaxError, OutOfMemory }!Expr {
    switch (self.token) {
        .LParen => {
            self.advance();

            const endtokens = .{TokenKind.RParen};
            var expr = try self.parse_expr(allocator, 0, &endtokens);

            try self.match(TokenKind.RParen);
            return expr;
        },
        .Identifier => {
            const id = self.token.Identifier;
            self.advance();

            if (self.expect(TokenKind.LParen)) {
                self.advance();

                if (self.expect(TokenKind.RParen)) {
                    self.advance();

                    var fncall = try allocator.create(FnCall);
                    fncall.id = id;
                    fncall.arguments = null;

                    return Expr{ .FnCallExpr = fncall };
                }

                var arguments = ArrayList(Expr).init(allocator);
                errdefer arguments.deinit();

                while (true) {
                    const endtokens = .{ TokenKind.Comma, TokenKind.RParen };
                    try arguments.append(try self.parse_expr(allocator, 0, &endtokens));

                    if (self.eof() or self.expect(TokenKind.RParen)) {
                        break;
                    }

                    try self.match(TokenKind.Comma);
                }

                try self.match(TokenKind.RParen);

                var fncall = try allocator.create(FnCall);
                fncall.id = id;
                fncall.arguments = null;

                return Expr{ .FnCallExpr = fncall };
            }

            const value = Value{ .Identifier = id };
            return Expr{ .ValueExpr = value };
        },
        .IntLiteral => {
            const value = Value{ .IntLiteral = self.token.IntLiteral };
            self.advance();
            return Expr{ .ValueExpr = value };
        },
        else => return ParserError.SyntaxError,
    }
}

fn parse_expr(self: *Self, allocator: Allocator, prec: u8, end_tokens: []const TokenKind) !Expr {
    var left = try self.parse_prim_expr(allocator);
    errdefer left.deinit(allocator);

    if (self.eof() or self.expect(TokenKind.Newline)) {
        return left;
    }

    for (end_tokens) |token| {
        if (self.expect(token)) {
            return left;
        }
    }

    const new_prec = self.expr_prec.get(self.token) orelse {
        return ParserError.SyntaxError;
    };

    if (new_prec == 0) {
        return ParserError.SyntaxError;
    }

    while (new_prec > prec) {
        const op = BinaryOp.from_token(self.token).?;
        self.advance();

        var right = try self.parse_expr(allocator, new_prec, end_tokens);
        errdefer right.deinit(allocator);

        var binary = try allocator.create(Binary);
        binary.op = op;
        binary.lhs = left;
        binary.rhs = right;

        left = Expr{ .BinaryExpr = binary };

        if (self.eof() or self.expect(TokenKind.Newline)) {
            return left;
        }

        for (end_tokens) |token| {
            if (self.expect(token)) {
                return left;
            }
        }
    }

    return left;
}

fn parse_type(self: *Self) !Type {
    const current = self.token;

    if (self.expect(TokenKind.Identifier)) {
        self.advance();
        return Type{ .UserDefined = current.Identifier };
    }

    try self.match(TokenKind.Int);

    return Type.Int;
}

fn parse_let_binding(self: *Self, allocator: Allocator) !Stmt {
    try self.match(TokenKind.Let);

    const id = self.token;

    try self.match(TokenKind.Identifier);
    try self.match(TokenKind.Colon);

    const tp = try self.parse_type();

    try self.match(TokenKind.Equal);

    const end_tokens = .{TokenKind.EndOfFile};
    var expr = try self.parse_expr(allocator, 0, &end_tokens);

    var let_binding = LetBinding{
        .id = id.Identifier,
        .type = tp,
        .expr = expr,
    };

    return Stmt{ .LetBindingStmt = let_binding };
}

pub fn parse_whole(self: *Self, allocator: Allocator) !void {
    self.advance();

    while (true) {
        self.skip_whitespaces();

        if (self.eof()) {
            return;
        }

        var stmt = try self.parse_let_binding(allocator);
        defer stmt.deinit(allocator);

        std.debug.print("{s}: {}\n", .{ stmt.LetBindingStmt.id, stmt.LetBindingStmt.type });
    }
}

pub fn init(input: []const u8, expr_prec: AutoHashMap(TokenKind, u8)) Self {
    return Self{
        .lexer = Lexer.init(input),
        .token = undefined,
        .expr_prec = expr_prec,
    };
}
