import Foundation

enum ReceiptParser {
    private static let stopwords: Set<String> = [
        "total", "subtotal", "tax", "cash", "change", "visa", "mastercard",
        "debit", "credit", "balance", "amount", "due", "receipt", "store",
        "thank", "card", "auth", "ref", "invoice", "date", "time", "qty",
        "price", "discount", "savings", "loyalty", "points", "tender",
        "approved", "payment", "cashier", "register"
    ]

    static func candidates(from lines: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in lines {
            guard let cleaned = clean(raw) else { continue }
            let key = cleaned.lowercased()
            if seen.insert(key).inserted {
                result.append(cleaned)
            }
        }
        return result
    }

    private static func clean(_ line: String) -> String? {
        var s = line.replacingOccurrences(
            of: #"[$£€]?\s?\d+([.,]\d{1,2})?"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"[^A-Za-z &]"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)

        guard s.count >= 3 else { return nil }
        let lower = s.lowercased()
        if stopwords.contains(where: { lower == $0 || lower.contains($0) }) { return nil }

        let letterRatio = Double(s.filter(\.isLetter).count) / Double(s.count)
        guard letterRatio > 0.6 else { return nil }

        return s.capitalized
    }
}
