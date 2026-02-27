import SwiftUI
import SwiftData
import Observation

@Observable
class HomeViewModel {
    func deleteRecipe(_ recipe: Recipe, context: ModelContext) {
        context.delete(recipe)
        try? context.save()
    }
}
