import SwiftUI
import SwiftData
import Observation

@Observable
class RecipeDetailViewModel {
    let recipe: Recipe
    var showingCookingFlow: Bool = false
    var checkedIngredients: Set<PersistentIdentifier> = []
    var showingDeferredRating: Bool = false
    var deferredRating: Int = 0
    var deferredNotes: String = ""

    // Scaling
    var scaleMultiplier: Double = 1.0
    var showingScalePicker: Bool = false
    var customQuantityText: String = ""

    private var sessionToRate: CookingSession? = nil

    // Add Ingredient
    var showingAddIngredient: Bool = false
    var newIngredientName: String = ""
    var newIngredientQuantity: String = ""

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    var category: RecipeCategory {
        RecipeCategory.detect(
            name: recipe.name,
            steps: recipe.steps.map(\.instruction)
        )
    }

    var hasIngredients: Bool {
        !recipe.ingredients.isEmpty
    }

    var hasSuggestions: Bool {
        !recipe.latestSuggestions.isEmpty
    }

    func scaledQuantity(for ingredient: Ingredient) -> String {
        ServingScaler.scale(quantity: ingredient.quantity, by: scaleMultiplier)
    }

    func applyCustomQuantity() {
        if let value = ServingScaler.parseFraction(customQuantityText), value > 0 {
            scaleMultiplier = value
            showingScalePicker = false
            customQuantityText = ""
        }
    }

    /// Only triggers once per session — checks for unprompted, unrated sessions
    func checkForUnratedSession() {
        if let session = recipe.unpromptedSession {
            sessionToRate = session
            deferredRating = 0
            deferredNotes = ""
            showingDeferredRating = true
        }
    }

    func toggleIngredient(_ id: PersistentIdentifier) {
        if checkedIngredients.contains(id) {
            checkedIngredients.remove(id)
        } else {
            checkedIngredients.insert(id)
        }
    }

    func isIngredientChecked(_ id: PersistentIdentifier) -> Bool {
        checkedIngredients.contains(id)
    }

    func submitDeferredRating() {
        guard let session = sessionToRate, deferredRating > 0 else { return }
        session.rating = deferredRating
        session.notes = deferredNotes
        session.suggestions = SuggestionEngine.generateSuggestions(from: deferredNotes)
        session.promptedForRating = true
        sessionToRate = nil
        showingDeferredRating = false
    }

    /// User dismissed — mark as prompted so it won't ask again, moves to notifications
    func dismissDeferredRating() {
        if let session = sessionToRate {
            session.promptedForRating = true
        }
        sessionToRate = nil
        showingDeferredRating = false
    }

    func addIngredient() {
        let name = newIngredientName.trimmingCharacters(in: .whitespaces)
        let qty = newIngredientQuantity.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let ingredient = Ingredient(name: name, quantity: qty.isEmpty ? "As needed" : qty)
        recipe.ingredients.append(ingredient)
        newIngredientName = ""
        newIngredientQuantity = ""
        showingAddIngredient = false
    }
}
