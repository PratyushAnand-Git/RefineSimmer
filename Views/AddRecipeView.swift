import SwiftUI
import SwiftData

struct AddRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AddRecipeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(Theme.textMain)
                            .font(Theme.bodyFont())
                        }
                        Spacer()
                        Text("Add Recipe")
                            .font(Theme.titleFont(size: 20))
                        Spacer()
                        Text("Back").opacity(0)
                    }
                    .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Theme.premiumIcon("pencil.and.outline", color: Theme.primary)
                            Text("RECIPE NAME")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                        }

                        TextField("e.g. Mom's Chicken Curry", text: $viewModel.recipeName)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.primaryLight, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Theme.premiumIcon("doc.text.badge.plus", color: Theme.primary)
                            Text("PASTE STEPS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                        }

                        ZStack(alignment: .topLeading) {
                            if viewModel.rawSteps.isEmpty {
                                Text("One step per line — numbered or plain, anything works.\n\n1. Heat oil in a pan\n2. Add onions, fry until golden\n3. Add tomatoes and cook 5 min\n4. Add chicken, simmer 20 min")
                                    .padding()
                                    .foregroundColor(Theme.textSecondary.opacity(0.6))
                                    .font(Theme.bodyFont())
                            }

                            TextEditor(text: $viewModel.rawSteps)
                                .padding(10)
                                .frame(minHeight: 250)
                                .scrollContentBackground(.hidden)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.primary, lineWidth: 1)
                                )
                        }
                    }

                    // Error display
                    if let error = viewModel.saveError {
                        Text(error)
                            .font(Theme.bodyFont(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }

                    Spacer()

                    PrimaryButton(title: "Save Recipe", action: {
                        viewModel.saveRecipe(context: modelContext)
                        if viewModel.didSave {
                            dismiss()
                        }
                    }, isLoading: viewModel.isSaving)
                    .disabled(!viewModel.canSave)
                    .opacity(viewModel.canSave ? 1 : 0.6)
                    .padding(.bottom, 20)
                }
                .padding(24)
            }
            .background(Theme.background)
        }
    }
}

#Preview {
    AddRecipeView()
        .modelContainer(for: [Recipe.self, Ingredient.self, Step.self, CookingSession.self], inMemory: true)
}
