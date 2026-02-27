import Foundation

/// Analyzes recipe steps and inserts implied prerequisite steps
/// (e.g., "sauté chopped onions" implies chopping onions + heating oil first)
struct StepPreprocessor {

    // Patterns: past-participle adjective → action verb + timer
    private static let prepPatterns: [(pattern: String, verb: String, durationSeconds: Int?)] = [
        ("chopped", "Chop", nil),
        ("diced", "Dice", nil),
        ("sliced", "Slice", nil),
        ("minced", "Mince", nil),
        ("grated", "Grate", nil),
        ("peeled", "Peel", nil),
        ("crushed", "Crush", nil),
        ("julienned", "Julienne", nil),
        ("shredded", "Shred", nil),
        ("cubed", "Cube", nil),
        ("boiled", "Boil", 600),      // 10 min
        ("blanched", "Blanch", 180),   // 3 min
        ("marinated", "Marinate", 900), // 15 min
        ("soaked", "Soak", 1800),      // 30 min
        ("roasted", "Roast", 900),     // 15 min
        ("toasted", "Toast", 120),     // 2 min
        ("melted", "Melt", 60),        // 1 min
        ("beaten", "Beat", nil),
        ("whisked", "Whisk", nil),
    ]

    // Actions that require a heated pan/oil
    private static let heatRequired: Set<String> = [
        "sauté", "saute", "fry", "stir fry", "stir-fry",
        "sear", "pan fry", "deep fry", "shallow fry", "toss"
    ]

    /// Process an array of steps, inserting prerequisite steps where implied
    static func preprocess(steps: [Step]) -> [Step] {
        var result: [Step] = []
        var alreadyInserted: Set<String> = [] // Track what preps we've already added
        var heatInserted = false

        for step in steps {
            let lower = step.instruction.lowercased()
            var prereqs: [Step] = []

            // 1. Detect implied prep steps from past-participles
            for prep in prepPatterns {
                if lower.contains(prep.pattern) {
                    // Find what ingredient follows the participle
                    let ingredientName = extractIngredientAfterWord(prep.pattern, in: lower)
                    if let name = ingredientName {
                        let key = "\(prep.verb.lowercased()) \(name)"
                        if !alreadyInserted.contains(key) && !stepAlreadyExists(verb: prep.verb.lowercased(), ingredient: name, in: steps) {
                            let prepStep = Step(
                                instruction: "\(prep.verb) the \(name)",
                                durationSeconds: prep.durationSeconds,
                                order: 0
                            )
                            prereqs.append(prepStep)
                            alreadyInserted.insert(key)
                        }
                    }
                }
            }

            // 2. Detect if heating oil/pan is needed
            if !heatInserted {
                for keyword in heatRequired {
                    if lower.contains(keyword) {
                        // Check if a heat step already exists
                        if !stepAlreadyExists(verb: "heat", ingredient: "oil", in: steps) {
                            let heatStep = Step(
                                instruction: "Heat oil in a pan on low flame",
                                durationSeconds: 120, // 2 min
                                order: 0
                            )
                            prereqs.append(heatStep)
                            heatInserted = true
                        }
                        break
                    }
                }
            }

            // Add prereqs before the current step
            result.append(contentsOf: prereqs)
            result.append(step)
        }

        // Re-number all steps
        for (index, step) in result.enumerated() {
            step.order = index
        }

        return result
    }

    /// Extract the ingredient name that follows a participle word
    /// e.g., "chopped onions" → "onions", "diced tomatoes" → "tomatoes"
    private static func extractIngredientAfterWord(_ word: String, in text: String) -> String? {
        guard let range = text.range(of: word) else { return nil }
        let after = text[range.upperBound...].trimmingCharacters(in: .whitespaces)

        // Take the first 1-2 words after the participle
        let words = after.split(separator: " ").prefix(2)
        guard !words.isEmpty else { return nil }

        // Filter out prepositions and conjunctions
        let stopWords: Set<String> = ["in", "on", "to", "and", "with", "the", "a", "an", "until", "for", "into"]
        let ingredientWords = words.filter { !stopWords.contains(String($0).lowercased()) }

        guard !ingredientWords.isEmpty else { return nil }
        return ingredientWords.joined(separator: " ").trimmingCharacters(in: .punctuationCharacters)
    }

    /// Check if a step with a similar verb+ingredient already exists in the original steps
    private static func stepAlreadyExists(verb: String, ingredient: String, in steps: [Step]) -> Bool {
        for step in steps {
            let lower = step.instruction.lowercased()
            if lower.contains(verb) && lower.contains(ingredient) {
                return true
            }
        }
        return false
    }
}
