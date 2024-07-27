import Foundation
import NaturalLanguage

class KeywordExtractionService: @unchecked Sendable {
    static let shared = KeywordExtractionService()
    
    private let stopWords: Set<String>
    
    private init() {
        self.stopWords = KeywordExtractionService.loadStopwords()
    }
    
    func extractKeywords(from comments: [Comment]) -> [(String, Int)] {
        let allComments = comments.map { $0.content }.joined(separator: " ")
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = allComments
        
        var wordFrequency: [String: Int] = [:]
        tokenizer.enumerateTokens(in: allComments.startIndex..<allComments.endIndex) { range, _ in
            let word = String(allComments[range]).lowercased()
            if word.count > 2 && !self.stopWords.contains(word) {
                wordFrequency[word, default: 0] += 1
            }
            return true
        }
        return wordFrequency.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
    }
}

extension KeywordExtractionService {
    static func loadStopwords() -> Set<String> {
        guard let url = Bundle.main.url(forResource: "Stopwords", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load Stopwords.json")
            return Set<String>()
        }
        
        do {
            let stopwordsArray = try JSONDecoder().decode([String].self, from: data)
            return Set(stopwordsArray)
        } catch {
            print("Failed to decode Stopwords.json: \(error)")
            return Set<String>()
        }
    }
}
