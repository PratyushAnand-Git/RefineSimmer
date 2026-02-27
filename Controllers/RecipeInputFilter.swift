import Foundation
import SwiftData

struct RecipeInputFilter {
    static func filterAndMapSteps(from input: String) -> [Step] {
        let lines = input.components(separatedBy: .newlines)

        return lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { shouldIncludeLine($0) }
            .enumerated()
            .map { index, line in
                let cleaned = removeStepPrefixes(line)
                let duration = extractDuration(from: cleaned)
                return Step(instruction: cleaned, durationSeconds: duration, order: index)
            }
    }

    private static func shouldIncludeLine(_ line: String) -> Bool {
        guard !line.isEmpty else { return false }

        if line.range(of: #"^\d+$"#, options: .regularExpression) != nil { return false }

        let noiseKeywords = ["visit", "website", "follow me", "subscribe", "page", "recipe from"]
        for keyword in noiseKeywords {
            if line.lowercased().contains(keyword) { return false }
        }

        return line.count > 3
    }

    private static func removeStepPrefixes(_ text: String) -> String {
        let pattern = #"^(Step\s*)?\d+[\.:\s]*|[•\-\*]\s*"#
        return text.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
    }

    private static func extractDuration(from text: String) -> Int? {
        let pattern = #"(\d+)\s*(min|minute|mins|minutes|sec|second|secs|seconds)"#
        if let range = text.lowercased().range(of: pattern, options: .regularExpression) {
            let match = String(text[range])
            let digits = match.filter { $0.isNumber }
            if let value = Int(digits) {
                if match.contains("min") {
                    return value * 60
                }
                return value
            }
        }
        return nil
    }
}
