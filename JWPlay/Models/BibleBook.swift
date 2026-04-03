import Foundation

struct BibleBook: Identifiable, Hashable {
    let id: Int         // booknum 1–66 (matches NWT API booknum field)
    let abbreviation: String
    let name: String
    let chapterCount: Int
    let testament: Testament

    enum Testament { case hebrew, greek }

    var isHebrew: Bool { testament == .hebrew }

    // Group size from lessons learned: 10 chapters per folder; skip grouping if <= 10
    static let chapterGroupSize = 10
    var needsChapterGroups: Bool { chapterCount > BibleBook.chapterGroupSize }

    // MARK: - Browse tree ID helpers
    var browsableID: String { "bible-\(testament == .hebrew ? "hebrew" : "greek")-\(id)" }
    func chapterGroupID(index: Int) -> String { "\(browsableID)-cg-\(index)" }
    func chapterID(chapter: Int) -> String { "\(browsableID)-ch-\(chapter)" }

    // MARK: - Static data
    static let all: [BibleBook] = hebrewScriptures + greekScriptures

    static let hebrewScriptures: [BibleBook] = [
        BibleBook(id: 1,  abbreviation: "Gen",  name: "Genesis",          chapterCount: 50, testament: .hebrew),
        BibleBook(id: 2,  abbreviation: "Ex",   name: "Exodus",           chapterCount: 40, testament: .hebrew),
        BibleBook(id: 3,  abbreviation: "Lev",  name: "Leviticus",        chapterCount: 27, testament: .hebrew),
        BibleBook(id: 4,  abbreviation: "Nu",   name: "Numbers",          chapterCount: 36, testament: .hebrew),
        BibleBook(id: 5,  abbreviation: "De",   name: "Deuteronomy",      chapterCount: 34, testament: .hebrew),
        BibleBook(id: 6,  abbreviation: "Jos",  name: "Joshua",           chapterCount: 24, testament: .hebrew),
        BibleBook(id: 7,  abbreviation: "Jg",   name: "Judges",           chapterCount: 21, testament: .hebrew),
        BibleBook(id: 8,  abbreviation: "Ru",   name: "Ruth",             chapterCount: 4,  testament: .hebrew),
        BibleBook(id: 9,  abbreviation: "1Sa",  name: "1 Samuel",         chapterCount: 31, testament: .hebrew),
        BibleBook(id: 10, abbreviation: "2Sa",  name: "2 Samuel",         chapterCount: 24, testament: .hebrew),
        BibleBook(id: 11, abbreviation: "1Ki",  name: "1 Kings",          chapterCount: 22, testament: .hebrew),
        BibleBook(id: 12, abbreviation: "2Ki",  name: "2 Kings",          chapterCount: 25, testament: .hebrew),
        BibleBook(id: 13, abbreviation: "1Ch",  name: "1 Chronicles",     chapterCount: 29, testament: .hebrew),
        BibleBook(id: 14, abbreviation: "2Ch",  name: "2 Chronicles",     chapterCount: 36, testament: .hebrew),
        BibleBook(id: 15, abbreviation: "Ezr",  name: "Ezra",             chapterCount: 10, testament: .hebrew),
        BibleBook(id: 16, abbreviation: "Ne",   name: "Nehemiah",         chapterCount: 13, testament: .hebrew),
        BibleBook(id: 17, abbreviation: "Es",   name: "Esther",           chapterCount: 10, testament: .hebrew),
        BibleBook(id: 18, abbreviation: "Job",  name: "Job",              chapterCount: 42, testament: .hebrew),
        BibleBook(id: 19, abbreviation: "Ps",   name: "Psalms",           chapterCount: 150, testament: .hebrew),
        BibleBook(id: 20, abbreviation: "Pr",   name: "Proverbs",         chapterCount: 31, testament: .hebrew),
        BibleBook(id: 21, abbreviation: "Ec",   name: "Ecclesiastes",     chapterCount: 12, testament: .hebrew),
        BibleBook(id: 22, abbreviation: "Ca",   name: "Song of Solomon",  chapterCount: 8,  testament: .hebrew),
        BibleBook(id: 23, abbreviation: "Isa",  name: "Isaiah",           chapterCount: 66, testament: .hebrew),
        BibleBook(id: 24, abbreviation: "Jer",  name: "Jeremiah",         chapterCount: 52, testament: .hebrew),
        BibleBook(id: 25, abbreviation: "La",   name: "Lamentations",     chapterCount: 5,  testament: .hebrew),
        BibleBook(id: 26, abbreviation: "Eze",  name: "Ezekiel",          chapterCount: 48, testament: .hebrew),
        BibleBook(id: 27, abbreviation: "Da",   name: "Daniel",           chapterCount: 12, testament: .hebrew),
        BibleBook(id: 28, abbreviation: "Ho",   name: "Hosea",            chapterCount: 14, testament: .hebrew),
        BibleBook(id: 29, abbreviation: "Joe",  name: "Joel",             chapterCount: 3,  testament: .hebrew),
        BibleBook(id: 30, abbreviation: "Am",   name: "Amos",             chapterCount: 9,  testament: .hebrew),
        BibleBook(id: 31, abbreviation: "Ob",   name: "Obadiah",          chapterCount: 1,  testament: .hebrew),
        BibleBook(id: 32, abbreviation: "Jon",  name: "Jonah",            chapterCount: 4,  testament: .hebrew),
        BibleBook(id: 33, abbreviation: "Mic",  name: "Micah",            chapterCount: 7,  testament: .hebrew),
        BibleBook(id: 34, abbreviation: "Na",   name: "Nahum",            chapterCount: 3,  testament: .hebrew),
        BibleBook(id: 35, abbreviation: "Hab",  name: "Habakkuk",         chapterCount: 3,  testament: .hebrew),
        BibleBook(id: 36, abbreviation: "Zep",  name: "Zephaniah",        chapterCount: 3,  testament: .hebrew),
        BibleBook(id: 37, abbreviation: "Hag",  name: "Haggai",           chapterCount: 2,  testament: .hebrew),
        BibleBook(id: 38, abbreviation: "Zec",  name: "Zechariah",        chapterCount: 14, testament: .hebrew),
        BibleBook(id: 39, abbreviation: "Mal",  name: "Malachi",          chapterCount: 4,  testament: .hebrew),
    ]

    static let greekScriptures: [BibleBook] = [
        BibleBook(id: 40, abbreviation: "Matt", name: "Matthew",          chapterCount: 28, testament: .greek),
        BibleBook(id: 41, abbreviation: "Mr",   name: "Mark",             chapterCount: 16, testament: .greek),
        BibleBook(id: 42, abbreviation: "Lu",   name: "Luke",             chapterCount: 24, testament: .greek),
        BibleBook(id: 43, abbreviation: "Joh",  name: "John",             chapterCount: 21, testament: .greek),
        BibleBook(id: 44, abbreviation: "Ac",   name: "Acts",             chapterCount: 28, testament: .greek),
        BibleBook(id: 45, abbreviation: "Ro",   name: "Romans",           chapterCount: 16, testament: .greek),
        BibleBook(id: 46, abbreviation: "1Co",  name: "1 Corinthians",    chapterCount: 16, testament: .greek),
        BibleBook(id: 47, abbreviation: "2Co",  name: "2 Corinthians",    chapterCount: 13, testament: .greek),
        BibleBook(id: 48, abbreviation: "Ga",   name: "Galatians",        chapterCount: 6,  testament: .greek),
        BibleBook(id: 49, abbreviation: "Eph",  name: "Ephesians",        chapterCount: 6,  testament: .greek),
        BibleBook(id: 50, abbreviation: "Php",  name: "Philippians",      chapterCount: 4,  testament: .greek),
        BibleBook(id: 51, abbreviation: "Col",  name: "Colossians",       chapterCount: 4,  testament: .greek),
        BibleBook(id: 52, abbreviation: "1Th",  name: "1 Thessalonians",  chapterCount: 5,  testament: .greek),
        BibleBook(id: 53, abbreviation: "2Th",  name: "2 Thessalonians",  chapterCount: 3,  testament: .greek),
        BibleBook(id: 54, abbreviation: "1Ti",  name: "1 Timothy",        chapterCount: 6,  testament: .greek),
        BibleBook(id: 55, abbreviation: "2Ti",  name: "2 Timothy",        chapterCount: 4,  testament: .greek),
        BibleBook(id: 56, abbreviation: "Tit",  name: "Titus",            chapterCount: 3,  testament: .greek),
        BibleBook(id: 57, abbreviation: "Phm",  name: "Philemon",         chapterCount: 1,  testament: .greek),
        BibleBook(id: 58, abbreviation: "Heb",  name: "Hebrews",          chapterCount: 13, testament: .greek),
        BibleBook(id: 59, abbreviation: "Jas",  name: "James",            chapterCount: 5,  testament: .greek),
        BibleBook(id: 60, abbreviation: "1Pe",  name: "1 Peter",          chapterCount: 5,  testament: .greek),
        BibleBook(id: 61, abbreviation: "2Pe",  name: "2 Peter",          chapterCount: 3,  testament: .greek),
        BibleBook(id: 62, abbreviation: "1Jo",  name: "1 John",           chapterCount: 5,  testament: .greek),
        BibleBook(id: 63, abbreviation: "2Jo",  name: "2 John",           chapterCount: 1,  testament: .greek),
        BibleBook(id: 64, abbreviation: "3Jo",  name: "3 John",           chapterCount: 1,  testament: .greek),
        BibleBook(id: 65, abbreviation: "Jude", name: "Jude",             chapterCount: 1,  testament: .greek),
        BibleBook(id: 66, abbreviation: "Re",   name: "Revelation",       chapterCount: 22, testament: .greek),
    ]

    // Lookup by NWT API booknum
    static let byBooknum: [Int: BibleBook] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    // All-caps names for WOL header parsing (e.g., "ISAIAH", "REVELATION")
    static let upperCaseNames: Set<String> = Set(all.map { $0.name.uppercased() })
    // Multi-word books need special handling ("SONG OF SOLOMON" etc.)
    static func book(forUpperCaseName name: String) -> BibleBook? {
        all.first { $0.name.uppercased() == name }
    }
}
