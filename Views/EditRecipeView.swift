import SwiftUI
import SwiftData

struct EditRecipeView: View {
    @Bindable var recipe: Recipe
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var newStepText: String = ""
    @State private var showingDeleteConfirm = false
    @State private var insertingAtOrder: Int? = nil
    @State private var insertStepText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Recipe Name
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Theme.premiumIcon("pencil.and.outline", color: Theme.primary)
                            Text("RECIPE NAME")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                        }

                        TextField("Recipe name", text: $recipe.name)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.primaryLight, lineWidth: 1)
                            )
                    }

                    // Steps
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Theme.premiumIcon("list.number", color: Theme.primary)
                            Text("STEPS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.bottom, 12)

                        // Insert before first step
                        insertButton(atOrder: 0)

                        ForEach(recipe.sortedSteps) { step in
                            // Step row
                            HStack(spacing: 12) {
                                Text("\(step.order + 1)")
                                    .font(Theme.bodyFont(size: 14).weight(.bold))
                                    .foregroundColor(Theme.primary)
                                    .frame(width: 24, height: 24)
                                    .background(Theme.primaryLight)
                                    .clipShape(Circle())

                                Text(step.instruction)
                                    .font(Theme.bodyFont(size: 14))
                                    .foregroundColor(Theme.textMain)

                                Spacer()

                                Button(action: {
                                    deleteStep(step)
                                }) {
                                    Theme.premiumIcon("trash.circle.fill", color: .red.opacity(0.6))
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)

                            // Insert after this step
                            insertButton(atOrder: step.order + 1)
                        }

                        // Add to end
                        HStack(spacing: 8) {
                            TextField("Add a new step...", text: $newStepText)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Theme.primaryLight, lineWidth: 1)
                                )

                            Button(action: addStepToEnd) {
                                Theme.premiumIcon("plus.circle.fill", color: Theme.primary)
                                    .font(.system(size: 28))
                            }
                            .disabled(newStepText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.top, 8)
                    }

                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Theme.premiumIcon("checklist", color: Theme.primary)
                            Text("INGREDIENTS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                        }

                        ForEach(recipe.ingredients) { ingredient in
                            HStack {
                                Text("\(ingredient.quantity) \(ingredient.name)")
                                    .font(Theme.bodyFont(size: 14))
                                    .foregroundColor(Theme.textMain)

                                Spacer()

                                Button(action: {
                                    recipe.ingredients.removeAll { $0.id == ingredient.id }
                                    modelContext.delete(ingredient)
                                    try? modelContext.save()
                                }) {
                                    Theme.premiumIcon("trash.circle.fill", color: .red.opacity(0.6))
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                        }

                        if recipe.ingredients.isEmpty {
                            Text("No ingredients added yet")
                                .font(Theme.bodyFont(size: 14))
                                .foregroundColor(Theme.textSecondary)
                                .italic()
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Delete Recipe
                    Button(action: { showingDeleteConfirm = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Recipe")
                                .font(Theme.bodyFont().weight(.bold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }
                }
                .padding(24)
            }
            .background(Theme.background)
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Delete Recipe?", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(recipe)
                    try? modelContext.save()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \"\(recipe.name)\" and all its cooking sessions.")
            }
        }
    }

    @ViewBuilder
    private func insertButton(atOrder order: Int) -> some View {
        if insertingAtOrder == order {
            HStack(spacing: 8) {
                TextField("New step...", text: $insertStepText)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.primary, lineWidth: 1.5)
                    )

                Button(action: { confirmInsert(at: order) }) {
                    Theme.premiumIcon("checkmark.circle.fill", color: Theme.success)
                        .font(.system(size: 24))
                }
                .disabled(insertStepText.trimmingCharacters(in: .whitespaces).isEmpty)

                Button(action: { cancelInsert() }) {
                    Theme.premiumIcon("xmark.circle.fill", color: Theme.textSecondary)
                        .font(.system(size: 24))
                }
            }
            .padding(.vertical, 6)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        } else {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    insertingAtOrder = order
                    insertStepText = ""
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("Insert step")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Theme.primary.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
        }
    }

    private func confirmInsert(at order: Int) {
        let trimmed = insertStepText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Shift existing steps at or after this order
        for step in recipe.steps where step.order >= order {
            step.order += 1
        }

        let newStep = Step(instruction: trimmed, order: order)
        recipe.steps.append(newStep)
        try? modelContext.save()

        withAnimation { insertingAtOrder = nil }
        insertStepText = ""
    }

    private func cancelInsert() {
        withAnimation { insertingAtOrder = nil }
        insertStepText = ""
    }

    private func deleteStep(_ step: Step) {
        let deletedOrder = step.order
        recipe.steps.removeAll { $0.id == step.id }
        modelContext.delete(step)

        // Reorder remaining steps
        for s in recipe.steps where s.order > deletedOrder {
            s.order -= 1
        }
        try? modelContext.save()
    }

    private func addStepToEnd() {
        let trimmed = newStepText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newOrder = (recipe.steps.map(\.order).max() ?? -1) + 1
        let step = Step(instruction: trimmed, order: newOrder)
        recipe.steps.append(step)
        try? modelContext.save()
        newStepText = ""
    }
}

#Preview {
    EditRecipeView(recipe: Recipe.sample)
        .modelContainer(for: Recipe.self, inMemory: true)
}
