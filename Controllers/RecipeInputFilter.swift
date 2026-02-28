import Foundation
import SwiftData

struct RecipeInputFilter {

    /// Result of parsing mixed input containing both ingredients and steps
    struct ParseResult {
        let steps: [Step]
        let parsedIngredients: [Ingredient]
    }

    // MARK: - Section Headers

    private static let ingredientHeaders: Set<String> = [
        "ingredients", "ingredient", "you will need", "you'll need",
        "what you need", "shopping list", "items needed", "things you need",
        "for ingredients", "ingredients list"
    ]

    private static let stepHeaders: Set<String> = [
        "recipe", "steps", "directions", "method", "instructions",
        "procedure", "preparation", "how to make", "how to cook",
        "cooking steps", "cooking method", "for instructions",
        "for steps", "for recipe", "for directions"
    ]

    // MARK: - Smart Parse

    static func smartParse(from input: String) -> ParseResult {
        let rawLines = input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var ingredientLines: [String] = []
        var stepLines: [String] = []
        var currentSection: SectionType = .unknown

        for line in rawLines {
            let cleaned = cleanForHeaderCheck(line)

            if isIngredientHeader(cleaned) {
                currentSection = .ingredients
                continue
            }
            if isStepHeader(cleaned) {
                currentSection = .steps
                continue
            }

            switch currentSection {
            case .ingredients:
                ingredientLines.append(line)
            case .steps:
                stepLines.append(line)
            case .unknown:
                if isLikelyIngredientLine(line) {
                    ingredientLines.append(line)
                } else if isLikelyStepLine(line) {
                    stepLines.append(line)
                } else if line.count > 3 {
                    stepLines.append(line)
                }
            }
        }

        // Fallback 1: no headers found and no ingredients detected
        if ingredientLines.isEmpty && currentSection == .unknown {
            let steps = buildSteps(from: rawLines)
            return ParseResult(steps: steps, parsedIngredients: [])
        }

        // Fallback 2: only ingredients detected (no steps)
        if stepLines.isEmpty && !ingredientLines.isEmpty {
            let steps = buildSteps(from: rawLines)
            return ParseResult(steps: steps, parsedIngredients: [])
        }

        // Merge step titles with their body descriptions
        let merged = mergeStepTitleAndBody(stepLines)
        let steps = buildSteps(from: merged)

        let ingredients = ingredientLines.compactMap { parseIngredientLine($0) }

        return ParseResult(steps: steps, parsedIngredients: ingredients)
    }

    // MARK: - Legacy

    static func filterAndMapSteps(from input: String) -> [Step] {
        let lines = input.components(separatedBy: .newlines)
        return buildSteps(from: lines)
    }

    // MARK: - Build Steps

    private static func buildSteps(from lines: [String]) -> [Step] {
        let cleaned = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { shouldIncludeLine($0) }
            .map { cleanStepText($0) }
            .filter { $0.count > 3 }

        return cleaned.enumerated().map { index, text in
            let duration = extractDuration(from: text)
            return Step(instruction: text, durationSeconds: duration, order: index)
        }
    }

    // MARK: - Merge Title + Body

    private static func mergeStepTitleAndBody(_ lines: [String]) -> [String] {
        var merged: [String] = []
        var i = 0

        while i < lines.count {
            let stripped = cleanStepText(lines[i])

            if isStepTitleLine(stripped) && i + 1 < lines.count {
                let nextStripped = cleanStepText(lines[i + 1])
                if nextStripped.split(separator: " ").count >= 3 {
                    // Body follows title — use body only
                    merged.append(lines[i + 1])
                    i += 2
                    continue
                }
            }

            // Skip pure title lines with no body (≤ 3 words, no verbs)
            if isStepTitleLine(stripped) && stripped.split(separator: " ").count <= 3 {
                i += 1
                continue
            }

            merged.append(lines[i])
            i += 1
        }

        return merged
    }

    private static func isStepTitleLine(_ text: String) -> Bool {
        let words = text.split(separator: " ")
        guard words.count <= 4 else { return false }

        // If it starts with the same verbs as cooking steps, NOT a title
        let firstWord = String(words.first ?? "").lowercased()
        let actionVerbs: Set<String> = [
            "add", "mix", "stir", "cook", "bake", "fry", "boil", "simmer",
            "heat", "pour", "chop", "dice", "slice", "spread", "whisk",
            "bring", "drain", "in", "top", "toss", "melt"
        ]
        if actionVerbs.contains(firstWord) { return false }

        // Most words are capitalized → title-like
        let capitalizedCount = words.filter { $0.first?.isUppercase == true }.count
        return capitalizedCount >= words.count / 2
    }

    // MARK: - Header Detection

    /// Clean a line for header checking: strip emojis and lowercase
    private static func cleanForHeaderCheck(_ line: String) -> String {
        var result = removeEmojis(from: line)

        // Remove step number prefixes (1., 2:, Step 3:) — but NOT quantity numbers
        result = result.replacingOccurrences(
            of: #"^(Step\s*)?\d+[\.\:\)]\s*"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        // Remove bullet points
        result = result.replacingOccurrences(
            of: #"^[•\-\*]\s*"#,
            with: "",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespaces)
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespaces)
    }

    private static func isIngredientHeader(_ text: String) -> Bool {
        return ingredientHeaders.contains(text) ||
               ingredientHeaders.contains(where: { text.hasPrefix($0) })
    }

    private static func isStepHeader(_ text: String) -> Bool {
        return stepHeaders.contains(text) ||
               stepHeaders.contains(where: { text.hasPrefix($0) })
    }

    // MARK: - Emoji Removal

    /// Remove emoji characters from a string (safe for Swift Playgrounds)
    private static func removeEmojis(from text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            let v = scalar.value
            // Skip emoji ranges
            if v >= 0x1F300 && v <= 0x1FAFF { continue }  // Misc symbols, emoticons, food
            if v >= 0x2600 && v <= 0x27BF { continue }    // Misc symbols
            if v >= 0xFE00 && v <= 0xFE0F { continue }    // Variation selectors
            if v == 0x200D { continue }                     // Zero-width joiner
            if v == 0x20E3 { continue }                     // Combining keycap
            if v >= 0xE0020 && v <= 0xE007F { continue }   // Tags
            if v >= 0x2700 && v <= 0x27BF { continue }     // Dingbats
            scalars.append(scalar)
        }
        return String(scalars)
    }

    // MARK: - Step Text Cleaning

    /// Clean step text: remove emojis + step number prefixes, but PRESERVE quantity numbers
    private static func cleanStepText(_ text: String) -> String {
        var result = removeEmojis(from: text)

        // Remove step number prefixes ONLY when followed by punctuation (. : ))
        // This preserves quantities like "200g", "2 tbsp"
        result = result.replacingOccurrences(
            of: #"^(Step\s*)?\d+[\.\:\)]\s*"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        // Remove bullet points
        result = result.replacingOccurrences(
            of: #"^[•\-\*]\s*"#,
            with: "",
            options: .regularExpression
        )

        result = result.trimmingCharacters(in: .whitespaces)

        // Capitalize first letter
        if let first = result.first {
            result = String(first).uppercased() + result.dropFirst()
        }
        return result
    }

    // MARK: - Line Classification

    private enum SectionType {
        case ingredients, steps, unknown
    }

    private static func isLikelyIngredientLine(_ line: String) -> Bool {
        let cleaned = cleanStepText(line).lowercased()
        let words = cleaned.split(separator: " ")

        if words.count > 6 { return false }

        // Quantity patterns: "200g", "2 cups", "½ tsp"
        let hasQuantity = cleaned.range(of: #"^\d+[\./]?\d*\s*(cups?|tbsp|tsp|g|kg|ml|oz|lb|pieces?|cloves?|medium|large|small)"#, options: .regularExpression) != nil
            || cleaned.range(of: #"[½¼¾⅓⅔]"#, options: .regularExpression) != nil

        // Parenthetical notes like (chopped), (optional), (to taste)
        let hasParenNote = cleaned.contains("(") && cleaned.contains(")")

        // First word is an action verb → step
        let firstWord = String(words.first ?? "")
        let actionVerbs: Set<String> = [
            "add", "mix", "stir", "cook", "bake", "fry", "boil", "simmer",
            "heat", "pour", "chop", "dice", "slice", "spread", "whisk",
            "fold", "knead", "serve", "garnish", "drizzle", "season",
            "marinate", "grill", "roast", "sauté", "saute", "combine",
            "preheat", "bring", "reduce", "transfer", "remove", "place",
            "let", "cover", "set", "flip", "turn", "cut", "peel",
            "brush", "coat", "toss", "beat", "blend", "melt", "top",
            "drain", "keep", "in"
        ]
        if actionVerbs.contains(firstWord) { return false }

        if hasQuantity { return true }
        if hasParenNote && words.count <= 5 { return true }
        if words.count <= 3 { return true }

        return false
    }

    private static func isLikelyStepLine(_ line: String) -> Bool {
        let cleaned = cleanStepText(line).lowercased()
        let words = cleaned.split(separator: " ")

        if words.count <= 2 { return false }

        let firstWord = String(words.first ?? "")
        let actionVerbs: Set<String> = [
            "add", "mix", "stir", "cook", "bake", "fry", "boil", "simmer",
            "heat", "pour", "chop", "dice", "slice", "spread", "whisk",
            "fold", "knead", "serve", "garnish", "drizzle", "season",
            "marinate", "grill", "roast", "sauté", "saute", "combine",
            "preheat", "bring", "reduce", "transfer", "remove", "place",
            "let", "cover", "set", "flip", "turn", "top", "drain",
            "keep", "toss", "melt", "in"
        ]
        if actionVerbs.contains(firstWord) { return true }
        if cleaned.range(of: #"\d+\s*(min|minute|sec|second|hour)"#, options: .regularExpression) != nil { return true }
        if cleaned.range(of: #"\d+\s*°"#, options: .regularExpression) != nil { return true }
        if words.count >= 5 && line.hasSuffix(".") { return true }

        return false
    }

    // MARK: - Ingredient Line Parser

    private static func parseIngredientLine(_ line: String) -> Ingredient? {
        let cleaned = removeEmojis(from: line).trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty, cleaned.count > 1 else { return nil }

        // Remove bullet/number prefixes but keep quantities
        let text = cleaned.replacingOccurrences(
            of: #"^[•\-\*]\s*"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        // Pattern: "200g pasta", "2 tbsp butter", "1 cup vegetables"
        let qtyPattern = #"^(\d+[\./]?\d*\s*(?:cups?|tbsp|tsp|tablespoons?|teaspoons?|oz|ounces?|lbs?|pounds?|kg|g|grams?|ml|liters?|litres?|pieces?|cloves?|slices?|bunch|pinch|dash|large|medium|small|whole)?)\s+(.+)"#
        if let regex = try? NSRegularExpression(pattern: qtyPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let qtyRange = Range(match.range(at: 1), in: text),
           let nameRange = Range(match.range(at: 2), in: text) {
            let qty = String(text[qtyRange]).trimmingCharacters(in: .whitespaces)
            let name = String(text[nameRange]).trimmingCharacters(in: .whitespaces)
            return Ingredient(name: name, quantity: qty)
        }

        // Fraction pattern: "½ tsp chili flakes"
        let fractionPattern = #"^([½¼¾⅓⅔]\s*(?:cups?|tbsp|tsp)?)\s+(.+)"#
        if let regex = try? NSRegularExpression(pattern: fractionPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let qtyRange = Range(match.range(at: 1), in: text),
           let nameRange = Range(match.range(at: 2), in: text) {
            let qty = String(text[qtyRange]).trimmingCharacters(in: .whitespaces)
            let name = String(text[nameRange]).trimmingCharacters(in: .whitespaces)
            return Ingredient(name: name, quantity: qty)
        }

        // No quantity — just name
        let defaultQty = IngredientExtractor.getDefaultQuantity(for: text)
        return Ingredient(name: text, quantity: defaultQty)
    }

    // MARK: - Filters

    private static func shouldIncludeLine(_ line: String) -> Bool {
        let stripped = removeEmojis(from: line).trimmingCharacters(in: .whitespaces)
        guard !stripped.isEmpty else { return false }
        if stripped.range(of: #"^\d+$"#, options: .regularExpression) != nil { return false }
        let noiseKeywords = ["visit", "website", "follow me", "subscribe", "page", "recipe from"]
        for keyword in noiseKeywords {
            if stripped.lowercased().contains(keyword) { return false }
        }
        return stripped.count > 3
    }

    private static func extractDuration(from text: String) -> Int? {
        // Handle ranges: "10–12 mins"
        let rangePattern = #"(\d+)\s*[–\-]\s*(\d+)\s*(min|minute|mins|minutes|sec|second|secs|seconds)"#
        if let regex = try? NSRegularExpression(pattern: rangePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let lowRange = Range(match.range(at: 1), in: text),
           let highRange = Range(match.range(at: 2), in: text),
           let unitRange = Range(match.range(at: 3), in: text) {
            let low = Int(text[lowRange]) ?? 0
            let high = Int(text[highRange]) ?? 0
            let avg = (low + high) / 2
            let unit = String(text[unitRange]).lowercased()
            return unit.hasPrefix("min") ? avg * 60 : avg
        }

        // Single: "10 min"
        let pattern = #"(\d+)\s*(min|minute|mins|minutes|sec|second|secs|seconds)"#
        if let range = text.lowercased().range(of: pattern, options: .regularExpression) {
            let match = String(text[range])
            let digits = match.filter { $0.isNumber }
            if let value = Int(digits) {
                return match.lowercased().contains("min") ? value * 60 : value
            }
        }
        return nil
    }
}
