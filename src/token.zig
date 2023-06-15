const std = @import("std");

pub const Token = union(TokenKind) {
    const Self = @This();

    //<BUILTIN TYPES>
    Int,

    // <LITERALS>
    Identifier: []const u8,
    IntLiteral: i64,

    // <SYMBOLS>
    LParen,
    RParen,
    LBrace,
    RBrace,
    Plus,
    Minus,
    Star,
    Slash,
    Percent,
    Equal,
    Colon,
    Newline,

    // <KEYWORDS>
    Let,
    Fn,
    Return,

    Illegal,
    EndOfFile,

    pub fn keyword(word: []const u8) ?Token {
        const map = std.ComptimeStringMap(Token, .{
            .{ "let", Token.Let },
            .{ "fn", Token.Fn },
            .{ "return", Token.Return },
        });

        return map.get(word);
    }
};

pub const TokenKind = enum {
    //<BUILTIN TYPES>
    Int,

    Identifier,
    IntLiteral,

    // <SYMBOLS>
    LParen,
    RParen,
    LBrace,
    RBrace,
    Plus,
    Minus,
    Star,
    Slash,
    Percent,
    Equal,
    Colon,
    Newline,

    // <KEYWORDS>
    Let,
    Fn,
    Return,

    Illegal,
    EndOfFile,
};
