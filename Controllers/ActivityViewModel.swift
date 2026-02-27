import SwiftUI
import Observation

@Observable
class ActivityViewModel {
    func allSessions(from recipes: [Recipe]) -> [(Recipe, CookingSession)] {
        var sessions: [(Recipe, CookingSession)] = []
        for recipe in recipes {
            for session in recipe.sessions {
                sessions.append((recipe, session))
            }
        }
        return sessions.sorted { $0.1.date > $1.1.date }
    }
}
