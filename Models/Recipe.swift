import Foundation
import SwiftData

@Model
class Ingredient {
    var name: String
    var quantity: String
    var isChecked: Bool

    init(name: String, quantity: String, isChecked: Bool = false) {
        self.name = name
        self.quantity = quantity
        self.isChecked = isChecked
    }
}

@Model
class Step {
    var instruction: String
    var durationSeconds: Int?
    var isCompleted: Bool
    var order: Int

    init(instruction: String, durationSeconds: Int? = nil, isCompleted: Bool = false, order: Int = 0) {
        self.instruction = instruction
        self.durationSeconds = durationSeconds
        self.isCompleted = isCompleted
        self.order = order
    }
}

@Model
class CookingSession {
    var date: Date
    var rating: Int
    var notes: String
    var suggestions: [String]
    var promptedForRating: Bool
    var dismissedFromNotification: Bool
    /// Once true, this session will NEVER appear for rating again (rated or permanently dismissed)
    var ratingFinalized: Bool

    init(date: Date = Date(), rating: Int = 0, notes: String = "", suggestions: [String] = [], promptedForRating: Bool = false, dismissedFromNotification: Bool = false, ratingFinalized: Bool = false) {
        self.date = date
        self.rating = rating
        self.notes = notes
        self.suggestions = suggestions
        self.promptedForRating = promptedForRating
        self.dismissedFromNotification = dismissedFromNotification
        self.ratingFinalized = ratingFinalized
    }

    /// Whether this session has been rated (rating > 0)
    var isRated: Bool { rating > 0 }

    /// Whether this session still needs a rating (not finalized, not rated)
    var needsRating: Bool { !isRated && !ratingFinalized }
}

@Model
class Recipe {
    var name: String
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient]
    @Relationship(deleteRule: .cascade) var steps: [Step]
    @Relationship(deleteRule: .cascade) var sessions: [CookingSession]

    init(name: String, ingredients: [Ingredient] = [], steps: [Step] = [], sessions: [CookingSession] = []) {
        self.name = name
        self.ingredients = ingredients
        self.steps = steps
        self.sessions = sessions
    }

    var attemptsCount: Int {
        sessions.count
    }

    var averageRating: Double {
        let rated = sessions.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return 0 }
        return rated.reduce(0.0) { $0 + Double($1.rating) } / Double(rated.count)
    }

    var latestSuggestions: [String] {
        sessions.last(where: { $0.rating > 0 })?.suggestions ?? []
    }

    var sortedSteps: [Step] {
        steps.sorted { $0.order < $1.order }
    }

    /// First session that was never prompted and still needs rating
    /// Used for the one-time deferred prompt when opening recipe detail
    var unpromptedSession: CookingSession? {
        sessions.first(where: { $0.needsRating && !$0.promptedForRating })
    }

    /// Unrated sessions shown in Activity "PENDING RATINGS" section
    var dismissedUnratedSessions: [CookingSession] {
        sessions.filter { $0.needsRating && $0.promptedForRating }
    }

    /// Sessions visible in the bell notification (prompted, not dismissed from bell, still needs rating)
    var bellNotificationSessions: [CookingSession] {
        sessions.filter { $0.needsRating && $0.promptedForRating && !$0.dismissedFromNotification }
    }

    static var sample: Recipe {
        let r = Recipe(name: "Mom's Chicken Curry")
        r.ingredients = [
            Ingredient(name: "Chicken", quantity: "500g"),
            Ingredient(name: "Onions", quantity: "2 large"),
            Ingredient(name: "Tomatoes", quantity: "3 medium")
        ]
        r.steps = [
            Step(instruction: "Heat oil in a large pan over medium heat", durationSeconds: 120, order: 0),
            Step(instruction: "Add onions and fry until golden brown", durationSeconds: 300, order: 1),
            Step(instruction: "Add tomatoes and cook until soft", durationSeconds: 300, order: 2),
            Step(instruction: "Add chicken pieces and simmer for 20 minutes", durationSeconds: 1200, order: 3)
        ]
        return r
    }
}
