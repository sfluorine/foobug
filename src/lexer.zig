const std = @import("std");
const tok = @import("./token.zig");

const Token = tok.Token;
const TokenKind = tok.TokenKind;

const Self = @This();

input: []const u8,

fn eof(self: *const Self) bool {
    return self.input.len == 0;
}

fn current(self: *const Self) u8 {
    return if (self.eof()) 0 else self.input[0];
}

fn advance(self: *Self) void {
    if (!self.eof()) {
        self.input = self.input[1..];
    }
}

fn skip_whitespaces(self: *Self) void {
    while (!self.eof() and std.ascii.isWhitespace(self.current()) and self.current() != '\n') {
        self.advance();
    }
}

fn get_identifier(self: *Self) Token {
    const start = self.input;
    var length: u8 = 0;

    while (true) {
        switch (self.current()) {
            'a'...'z', 'A'...'Z', '_' => {
                length += 1;
                self.advance();
            },
            else => break,
        }
    }

    const span = start[0..length];

    if (Token.keyword(span)) |token| {
        return token;
    }

    return Token{ .Identifier = span };
}

fn get_int_literal(self: *Self) Token {
    const start = self.input;
    var length: u8 = 0;

    while (true) {
        switch (self.current()) {
            '0'...'9' => {
                length += 1;
                self.advance();
            },
            else => break,
        }
    }

    const span = start[0..length];
    const value = std.fmt.parseInt(i64, span, 10) catch {
        return Token.Illegal;
    };

    return Token{ .IntLiteral = value };
}

pub fn get_token(self: *Self) Token {
    self.skip_whitespaces();

    if (self.eof()) {
        return Token.EndOfFile;
    }

    const token: Token = switch (self.current()) {
        '(' => .LParen,
        ')' => .RParen,
        '{' => .LBrace,
        '}' => .RBrace,
        '+' => .Plus,
        '-' => .Minus,
        '*' => .Star,
        '/' => .Slash,
        '%' => .Percent,
        '=' => .Equal,
        ':' => .Colon,
        ',' => .Comma,
        '\n' => .Newline,
        'a'...'z', 'A'...'Z', '_' => return self.get_identifier(),
        '0'...'9' => return self.get_int_literal(),
        else => {
            std.log.err("unimplemented token: {}", .{self.current()});
            return .Illegal;
        },
    };

    self.advance();

    return token;
}

pub fn init(input: []const u8) Self {
    return Self{
        .input = input,
    };
}
