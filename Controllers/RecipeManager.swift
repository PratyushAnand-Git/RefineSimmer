import Foundation

struct SuggestionEngine {
    static func generateSuggestions(from notes: String) -> [String] {
        var suggestions: [String] = []
        let lowerNotes = notes.lowercased()

        if lowerNotes.contains("too salty") {
            suggestions.append("Reduce salt by 10%")
        }
        if lowerNotes.contains("overcooked") || lowerNotes.contains("too dry") {
            suggestions.append("Reduce cook time by 2 minutes")
        }
        if lowerNotes.contains("bland") {
            suggestions.append("Add more spices or seasoning")
        }
        if lowerNotes.contains("spicy") {
            suggestions.append("Reduce heat/chili amount")
        }

        return suggestions
    }
}
