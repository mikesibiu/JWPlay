import Foundation

/// Parses HTML from wol.jw.org MWB weekly pages to extract:
///  - CBS lesson numbers
///  - Bible reading chapter range
///
/// Parsing strategy mirrors Android MwbScheduleProvider exactly:
///  - CBS: anchor search from "Congregation Bible Study" marker (500 char window)
///  - Header: search only first 3000 chars to avoid false positives
struct WOLParser {

    // MARK: - CBS lesson numbers

    /// Returns lesson numbers from text like "lfb lessons 68-69" or
    /// "lfb intro to section 11 and lessons 68-69".
    /// Searches within 500 chars of "Congregation Bible Study" — mirrors Android.
    static func parseCBSLessons(from html: String) -> [Int] {
        let text = stripHTML(html)

        // Anchor search from "Congregation Bible Study" marker (Android approach)
        guard let markerRange = text.range(of: "Congregation Bible Study") else { return [] }
        let excerptStart = markerRange.lowerBound
        let excerptEnd   = text.index(excerptStart, offsetBy: 500, limitedBy: text.endIndex) ?? text.endIndex
        let excerpt      = String(text[excerptStart..<excerptEnd])

        guard let match = excerpt.range(of: #"(?i)lessons?\s+(\d+)(?:[-–](\d+))?"#,
                                         options: .regularExpression) else { return [] }
        let snippet = String(excerpt[match])

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

    /// Extracts Bible chapter range from MWB page.
    /// Strategy 1: header "ISAIAH 43-44" (first 3000 chars only — Android approach)
    /// Strategy 2: Bible Reading line "Isa 44:9-20"
    static func parseBibleRange(from html: String) -> BibleRange? {
        let text = stripHTML(html)
        if let range = parseFromHeader(text) { return range }
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
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return result
    }

    /// Search first 3000 chars for "WORD(S) digits-digits", skip non-Bible-book words.
    /// Mirrors Android: `val searchArea = html.take(3000)` + `BibleBooks.findByName`.
    private static func parseFromHeader(_ text: String) -> BibleRange? {
        let searchArea = String(text.prefix(3000))
        let pattern = #"([A-Za-z]+(?:\s+[A-Za-z]+)?)\s+(\d+)[–\-](\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let matches = regex.matches(in: searchArea, range: NSRange(searchArea.startIndex..., in: searchArea))

        for match in matches {
            guard match.numberOfRanges == 4,
                  let wordRange  = Range(match.range(at: 1), in: searchArea),
                  let startRange = Range(match.range(at: 2), in: searchArea),
                  let endRange   = Range(match.range(at: 3), in: searchArea) else { continue }

            let word  = String(searchArea[wordRange])
            let start = Int(searchArea[startRange]) ?? 0
            let endCh = Int(searchArea[endRange])   ?? 0

            guard let book = BibleBook.book(forUpperCaseName: word.uppercased()),
                  start > 0, endCh > start else { continue }

            return BibleRange(booknum: book.id, startChapter: start, endChapter: endCh)
        }
        return nil
    }

    /// Fallback: "Bible Reading (4 min.) Isa 44:9-20" → end chapter 44.
    /// Mirrors Android's parseBibleReadingEndChapter: searches 300 chars from marker.
    private static func parseFromBibleReadingLine(_ text: String) -> BibleRange? {
        guard let markerRange = text.range(of: "Bible Reading") else { return nil }
        let excerptEnd = text.index(markerRange.lowerBound, offsetBy: 300, limitedBy: text.endIndex) ?? text.endIndex
        let excerpt    = String(text[markerRange.lowerBound..<excerptEnd])

        let pattern = #"([A-Za-z]+)\s+(\d+):\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: excerpt, range: NSRange(excerpt.startIndex..., in: excerpt)),
              match.numberOfRanges == 3,
              let abbrRange = Range(match.range(at: 1), in: excerpt),
              let chRange   = Range(match.range(at: 2), in: excerpt) else { return nil }

        let abbr    = String(excerpt[abbrRange])
        guard let chapter = Int(excerpt[chRange]),
              let book = BibleBook.all.first(where: { $0.abbreviation == abbr }) else { return nil }

        // Fallback only gives us end chapter; infer start = end - 1 (typical 2-chapter weekly reading)
        return BibleRange(booknum: book.id, startChapter: max(1, chapter - 1), endChapter: chapter)
    }
}
