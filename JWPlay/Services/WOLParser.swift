import Foundation

/// Parses HTML from wol.jw.org MWB weekly pages to extract:
///  - CBS lesson numbers
///  - Bible reading chapter range
struct WOLParser {

    // MARK: - CBS lesson numbers

    /// Returns lesson numbers from text like "lfb lessons 68-69" or
    /// "lfb intro to section 11 and lessons 68-69"
    static func parseCBSLessons(from html: String) -> [Int] {
        let text = stripHTML(html)
        // Match "lfb" followed eventually by "lesson(s) N" with optional "-M"
        guard let match = text.range(of: #"(?i)lfb[^.]*?lessons?\s+(\d+)(?:\s*[-–]\s*(\d+))?"#,
                                      options: .regularExpression) else {
            return []
        }
        let snippet = String(text[match])
        // Extract all digit sequences after "lesson"
        guard let lessonRange = snippet.range(of: #"(?i)lessons?\s+"#, options: .regularExpression) else {
            return []
        }
        let afterLesson = String(snippet[lessonRange.upperBound...])
        let parts = afterLesson
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
            .prefix(2)
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

        if parts.count == 2, parts[1] >= parts[0] {
            return Array(parts[0]...parts[1])
        } else if let first = parts.first {
            return [first]
        }
        return []
    }

    // MARK: - Bible chapter range

    struct BibleRange {
        let booknum: Int
        let startChapter: Int
        let endChapter: Int
    }

    /// Extracts Bible chapter range from MWB page header like "MARCH 9-15 ISAIAH 43-44"
    /// Falls back to Bible Reading line "Bible Reading (4 min.) Isa 44:9-20"
    static func parseBibleRange(from html: String) -> BibleRange? {
        let text = stripHTML(html)

        // Strategy 1: find "BOOKNAME digits-digits" in the page header area
        if let range = parseFromHeader(text) { return range }

        // Strategy 2: parse "Bible Reading ... Abbrev chapter:verse"
        if let range = parseFromBibleReadingLine(text) { return range }

        return nil
    }

    // MARK: - Private helpers

    private static func stripHTML(_ html: String) -> String {
        var result = html
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#160;", with: " ")
        // Collapse whitespace
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return result
    }

    private static func parseFromHeader(_ text: String) -> BibleRange? {
        // Find all occurrences of WORD(S) digits-digits
        // Then check if the word part is a Bible book name
        let pattern = #"([A-Z][A-Z]+(?:\s+[A-Z][A-Z]+)*)\s+(\d+)\s*[-–]\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches {
            guard match.numberOfRanges == 4 else { continue }
            let wordRange = Range(match.range(at: 1), in: text)
            let startRange = Range(match.range(at: 2), in: text)
            let endRange   = Range(match.range(at: 3), in: text)

            guard let wr = wordRange, let sr = startRange, let er = endRange else { continue }
            let word  = String(text[wr]).uppercased()
            let start = Int(text[sr]) ?? 0
            let end   = Int(text[er]) ?? 0

            // Skip date ranges (months) — check if word is a known Bible book name
            if let book = BibleBook.book(forUpperCaseName: word), start > 0, end > 0 {
                return BibleRange(booknum: book.id, startChapter: start, endChapter: end)
            }

            // Handle multi-word names by scanning all books
            // (NSString range already handles multi-word via the pattern above)
            _ = nsText // suppress unused warning
        }
        return nil
    }

    private static func parseFromBibleReadingLine(_ text: String) -> BibleRange? {
        // Match "Bible Reading" line: "Bible Reading (4 min.) Isa 44:9-20"
        let pattern = #"Bible Reading[^\n]*?([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s+(\d+):\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges == 3 else { return nil }

        guard let abbrRange = Range(match.range(at: 1), in: text),
              let chRange   = Range(match.range(at: 2), in: text) else { return nil }

        let abbr = String(text[abbrRange])
        guard let chapter = Int(text[chRange]) else { return nil }

        // Match abbreviation to book
        if let book = BibleBook.all.first(where: { $0.abbreviation == abbr }) {
            // From fallback we only know end chapter; assume start = end - 1 for typical 2-chapter reading
            let startChapter = max(1, chapter - 1)
            return BibleRange(booknum: book.id, startChapter: startChapter, endChapter: chapter)
        }
        return nil
    }
}
