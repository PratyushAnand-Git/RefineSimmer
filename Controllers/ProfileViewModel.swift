import SwiftUI
import Observation

@Observable
class ProfileViewModel {
    var isEditingName: Bool = false

    func recipeCount(_ recipes: [Recipe]) -> Int {
        recipes.count
    }

    func totalSessions(_ recipes: [Recipe]) -> Int {
        recipes.reduce(0) { $0 + $1.sessions.count }
    }

    func avgRating(_ recipes: [Recipe]) -> String {
        let count = totalSessions(recipes)
        guard count > 0 else { return "-" }

        let ratedSessions = recipes.flatMap { $0.sessions }.filter { $0.rating > 0 }
        guard !ratedSessions.isEmpty else { return "-" }

        let sumRating = ratedSessions.reduce(0.0) { $0 + Double($1.rating) }
        return String(format: "%.1f", sumRating / Double(ratedSessions.count))
    }

    func toggleEditing() {
        isEditingName.toggle()
    }
}
