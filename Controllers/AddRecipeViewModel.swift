import SwiftUI
import SwiftData
import Observation

@Observable
class AddRecipeViewModel {
    var recipeName: String = ""
    var rawSteps: String = ""
    var isSaving: Bool = false
    var didSave: Bool = false
    var saveError: String? = nil

    var canSave: Bool {
        !recipeName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !rawSteps.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func saveRecipe(context: ModelContext) {
        guard canSave else {
            saveError = "Please enter a recipe name and steps."
            return
        }

        isSaving = true
        saveError = nil

        // 1. Parse raw text into Step objects
        let parsedSteps = RecipeInputFilter.filterAndMapSteps(from: rawSteps)
        guard !parsedSteps.isEmpty else {
            saveError = "Could not parse any steps from the input."
            isSaving = false
            return
        }

        // 2. Insert implied prerequisite steps
        let processedSteps = StepPreprocessor.preprocess(steps: parsedSteps)

        // 3. Detect cooking actions and apply smart timer durations
        for step in processedSteps {
            if step.durationSeconds == nil {
                let action = IngredientExtractor.detectCookingAction(from: step.instruction)
                if let suggestedDuration = IngredientExtractor.suggestDuration(for: action) {
                    step.durationSeconds = suggestedDuration
                }
            }
        }

        // 4. Extract ingredients from the full expanded step list
        let stepInstructions = processedSteps.map(\.instruction)
        let extractedIngredients = IngredientExtractor.extractIngredients(from: stepInstructions)

        // 5. Create and insert recipe
        let recipe = Recipe(
            name: recipeName.trimmingCharacters(in: .whitespaces),
            ingredients: extractedIngredients,
            steps: processedSteps
        )

        context.insert(recipe)

        // 6. Explicitly persist
        do {
            try context.save()
            didSave = true
            print("✅ Recipe '\(recipe.name)' saved with \(processedSteps.count) steps and \(extractedIngredients.count) ingredients")
        } catch {
            saveError = "Save failed: \(error.localizedDescription)"
            print("❌ Save failed: \(error)")
        }

        isSaving = false
    }
}
