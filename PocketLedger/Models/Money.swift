import Foundation

enum LedgerError: LocalizedError {
    case invalidAmount, invalidCategory, noteTooLong
    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "请输入 0.01～999,999,999.99 的金额，最多两位小数。"
        case .invalidCategory: return "请选择与收支类型对应的分类。"
        case .noteTooLong: return "备注不能超过 100 个字符。"
        }
    }
}

enum Money {
    static let maximumCents: Int64 = 99_999_999_999

    // Parse digits directly: no binary floating-point arithmetic in the money path.
    static func parse(_ input: String) throws -> Int64 {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.range(of: #"^[0-9]+(?:\.[0-9]{1,2})?$"#,
                         options: .regularExpression) != nil else {
            throw LedgerError.invalidAmount
        }
        let parts = text.split(separator: ".")
        guard let whole = Int64(parts[0]) else { throw LedgerError.invalidAmount }
        let fraction = parts.count == 2 ? String(parts[1]) : ""
        let cents = Int64(fraction.padding(toLength: 2, withPad: "0", startingAt: 0)) ?? 0
        let (base, overflow) = whole.multipliedReportingOverflow(by: 100)
        let (result, additionOverflow) = base.addingReportingOverflow(cents)
        guard !overflow, !additionOverflow, result > 0, result <= maximumCents else {
            throw LedgerError.invalidAmount
        }
        return result
    }

    static func formatted(_ cents: Int64) -> String {
        (Decimal(cents) / 100).formatted(.currency(code: "CNY").locale(Locale(identifier: "zh_CN")))
    }
}
