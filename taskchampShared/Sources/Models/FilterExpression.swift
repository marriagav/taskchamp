import Foundation

// MARK: - FilterExpression

public indirect enum FilterExpression {
    case and([FilterExpression])
    case or([FilterExpression])
    case tag(String)
    case notTag(String)
    case project(String)
    case priority(TCTask.Priority)
    case status(TCTask.Status)
    case recur

    public func matches(_ task: TCTask) -> Bool {
        switch self {
        case .and(let expressions):
            return expressions.allSatisfy { $0.matches(task) }
        case .or(let expressions):
            return expressions.contains { $0.matches(task) }
        case .tag(let name):
            return task.tags?.contains { $0.name == name } ?? false
        case .notTag(let name):
            return !(task.tags?.contains { $0.name == name } ?? false)
        case .project(let name):
            return task.project == name
        case .priority(let prio):
            let taskPrio = task.priority ?? .none
            return taskPrio == prio
        case .status(let status):
            return task.status == status
        case .recur:
            return task.recur != nil
        }
    }

    func containsStatus(_ status: TCTask.Status) -> Bool {
        switch self {
        case .status(let taskStatus):
            return taskStatus == status
        case .and(let expressions), .or(let expressions):
            return expressions.contains { $0.containsStatus(status) }
        default:
            return false
        }
    }
}

// MARK: - FilterToken

enum FilterToken: Equatable {
    case leftParen
    case rightParen
    case orKeyword
    case andKeyword
    case tag(String)
    case notTag(String)
    case project(String)
    case priority(String)
    case status(String)
    case recur
}

// MARK: - FilterParser

public struct FilterParser {

    // MARK: - Public API

    public static func parse(_ input: String) -> FilterExpression? {
        let tokens = tokenize(input)
        guard !tokens.isEmpty else { return nil }
        var index = 0
        let result = parseOrExpression(tokens: tokens, index: &index)
        return result
    }

    // MARK: - Tokenizer

    static func tokenize(_ input: String) -> [FilterToken] {
        var tokens: [FilterToken] = []
        let chars = Array(input)
        var i = 0

        while i < chars.count {
            if chars[i].isWhitespace {
                i += 1
                continue
            }

            if chars[i] == "(" {
                tokens.append(.leftParen)
                i += 1
                continue
            }

            if chars[i] == ")" {
                tokens.append(.rightParen)
                i += 1
                continue
            }

            var word = ""
            while i < chars.count && !chars[i].isWhitespace && chars[i] != "(" && chars[i] != ")" {
                word.append(chars[i])
                i += 1
            }

            guard !word.isEmpty else { continue }

            if word.lowercased() == "or" {
                tokens.append(.orKeyword)
            } else if word.lowercased() == "and" {
                tokens.append(.andKeyword)
            } else if word.hasPrefix("project:") {
                tokens.append(.project(String(word.dropFirst("project:".count))))
            } else if word.hasPrefix("prio:") {
                tokens.append(.priority(String(word.dropFirst("prio:".count))))
            } else if word.hasPrefix("status:") {
                tokens.append(.status(String(word.dropFirst("status:".count))))
            } else if word.lowercased() == "recur" {
                tokens.append(.recur)
            } else if word.hasPrefix("+") {
                let value = String(word.dropFirst())
                if !value.isEmpty {
                    tokens.append(.tag(value))
                }
            } else if word.hasPrefix("-") {
                let value = String(word.dropFirst())
                if !value.isEmpty {
                    tokens.append(.notTag(value))
                }
            }
        }

        return tokens
    }

    // MARK: - Recursive Descent Parser
    //
    // Grammar:
    //   expression = or_expr
    //   or_expr    = and_expr ("or" and_expr)*
    //   and_expr   = primary ("and"? primary)*
    //   primary    = "(" expression ")" | atom
    //   atom       = tag | notTag | project | priority | status | recur

    private static func parseOrExpression(tokens: [FilterToken], index: inout Int) -> FilterExpression? {
        guard let first = parseAndExpression(tokens: tokens, index: &index) else { return nil }

        var operands = [first]
        while index < tokens.count && tokens[index] == .orKeyword {
            index += 1
            guard let next = parseAndExpression(tokens: tokens, index: &index) else { break }
            operands.append(next)
        }

        return operands.count == 1 ? operands[0] : .or(operands)
    }

    private static func parseAndExpression(tokens: [FilterToken], index: inout Int) -> FilterExpression? {
        guard let first = parsePrimary(tokens: tokens, index: &index) else { return nil }

        var operands = [first]
        while index < tokens.count && tokens[index] != .orKeyword && tokens[index] != .rightParen {
            if tokens[index] == .andKeyword {
                index += 1
            }
            guard let next = parsePrimary(tokens: tokens, index: &index) else { break }
            operands.append(next)
        }

        return operands.count == 1 ? operands[0] : .and(operands)
    }

    private static func parsePrimary(tokens: [FilterToken], index: inout Int) -> FilterExpression? {
        guard index < tokens.count else { return nil }

        if tokens[index] == .leftParen {
            index += 1
            guard let expr = parseOrExpression(tokens: tokens, index: &index) else { return nil }
            if index < tokens.count && tokens[index] == .rightParen {
                index += 1
            }
            return expr
        }

        return parseAtom(tokens: tokens, index: &index)
    }

    private static func parseAtom(tokens: [FilterToken], index: inout Int) -> FilterExpression? {
        guard index < tokens.count else { return nil }

        let token = tokens[index]

        switch token {
        case .tag(let name):
            index += 1
            return .tag(name)
        case .notTag(let name):
            index += 1
            return .notTag(name)
        case .project(let value):
            index += 1
            return .project(value)
        case .priority(let value):
            index += 1
            guard let prio = TCTask.Priority(rawValue: value) else { return nil }
            return .priority(prio)
        case .status(let value):
            index += 1
            guard let status = TCTask.Status(rawValue: value) else { return nil }
            return .status(status)
        case .recur:
            index += 1
            return .recur
        default:
            return nil
        }
    }
}
