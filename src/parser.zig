const std = @import("std");
const tok = @import("./token.zig");

const Lexer = @import("./lexer.zig");
const AutoHashMap = std.AutoHashMap;
const Token = tok.Token;
const TokenKind = tok.TokenKind;

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

fn advance(self: *Self) void {
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

fn parse_prim_expr(self: *Self) !void {
    switch (self.token) {
        .LParen => {
            self.advance();
            try self.parse_expr(0);
            try self.match(TokenKind.RParen);
        },
        .Identifier => {
            self.advance();

            if (self.expect(TokenKind.LParen)) {
                self.advance();

                while (true) {
                    self.skip_whitespaces();

                    if (self.eof() or self.expect(TokenKind.RParen)) {
                        break;
                    }

                    try self.parse_expr(0);

                    if (self.eof() or self.expect(TokenKind.RParen)) {
                        break;
                    }

                    try self.match(TokenKind.Comma);
                }

                try self.match(TokenKind.RParen);
            }
        },
        .IntLiteral => self.advance(),
        else => return ParserError.SyntaxError,
    }
}

fn parse_expr(self: *Self, prec: u8) ParserError!void {
    try self.parse_prim_expr();

    if (self.eof() or self.expect(TokenKind.Newline) or self.expect(TokenKind.Comma) or self.expect(TokenKind.RParen)) {
        return;
    }

    const new_prec = self.expr_prec.get(self.token) orelse {
        return ParserError.SyntaxError;
    };

    if (new_prec == 0) {
        return ParserError.SyntaxError;
    }

    while (new_prec > prec) {
        self.advance();

        try self.parse_expr(new_prec);

        if (self.eof() or self.expect(TokenKind.Newline) or self.expect(TokenKind.Comma) or self.expect(TokenKind.RParen)) {
            return;
        }
    }
}

fn parse_type(self: *Self) !void {
    if (self.expect(TokenKind.Identifier)) {
        self.advance();
        return;
    }

    try self.match(TokenKind.Int);
}

fn parse_let_binding(self: *Self) !void {
    try self.match(TokenKind.Let);
    try self.match(TokenKind.Identifier);
    try self.match(TokenKind.Colon);
    try self.parse_type();
    try self.match(TokenKind.Equal);
    try self.parse_expr(0);

    if (!self.expect(TokenKind.EndOfFile) and !self.expect(TokenKind.Newline)) {
        return ParserError.SyntaxError;
    }

    self.advance();
}

fn parse_statement(self: *Self) !void {
    if (self.expect(TokenKind.Return)) {
        self.advance();

        try self.parse_expr(0);
        return;
    }

    try self.parse_let_binding();
}

fn parse_function_prototype(self: *Self) !void {
    try self.match(TokenKind.Fn);
    try self.match(TokenKind.Identifier);
    try self.match(TokenKind.LParen);

    while (true) {
        self.skip_whitespaces();

        if (self.eof() or self.expect(TokenKind.RParen)) {
            break;
        }

        try self.match(TokenKind.Identifier);
        try self.match(TokenKind.Colon);
        try self.parse_type();

        if (self.eof() or self.expect(TokenKind.RParen)) {
            break;
        }

        try self.match(TokenKind.Comma);
    }

    try self.match(TokenKind.RParen);
    try self.parse_type();
}

fn parse_block(self: *Self) !void {
    try self.match(TokenKind.LBrace);

    while (true) {
        self.skip_whitespaces();

        if (self.eof() or self.expect(TokenKind.RBrace)) {
            break;
        }

        try self.parse_statement();
    }

    try self.match(TokenKind.RBrace);
}

fn parse_function(self: *Self) !void {
    try self.parse_function_prototype();
    try self.parse_block();
}

pub fn parse_whole(self: *Self) !void {
    self.advance();

    while (true) {
        self.skip_whitespaces();

        if (self.eof()) {
            return;
        }

        try self.parse_function();
    }
}

pub fn init(input: []const u8, expr_prec: AutoHashMap(TokenKind, u8)) Self {
    return Self{
        .lexer = Lexer.init(input),
        .token = undefined,
        .expr_prec = expr_prec,
    };
}
