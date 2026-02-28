import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(AppNavigation.self) private var appNav: AppNavigation?

    init(recipe: Recipe) {
        _viewModel = State(initialValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title + Scale Button
                    HStack(alignment: .top) {
                        Text(viewModel.recipe.name)
                            .font(Theme.titleFont(size: 32))

                        Spacer()

                        Button(action: {
                            viewModel.showingScalePicker.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "scalemass.fill")
                                    .font(.system(size: 14))
                                Text(scaleLabel)
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(Theme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Theme.primaryLight)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)

                    // Scale Picker
                    if viewModel.showingScalePicker {
                        scalePicker
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if viewModel.hasSuggestions {
                        suggestionsSection
                    }

                    timeEstimateSection

                    ingredientsSection

                    stepsSection
                }
                .padding(.vertical)
            }

            VStack {
                Divider()
                PrimaryButton(title: "Start Cooking Session") {
                    viewModel.showingCookingFlow = true
                }
                .padding(24)
            }
            .background(Color.white)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.background)
        .animation(.easeInOut(duration: 0.25), value: viewModel.showingScalePicker)
        .onAppear {
            viewModel.checkForUnratedSession()
        }
        .fullScreenCover(isPresented: $viewModel.showingCookingFlow) {
            GuidedCookingView(recipe: viewModel.recipe, optimizedStepIds: viewModel.optimizedStepIds)
        }
        .sheet(isPresented: $viewModel.showingDeferredRating) {
            DeferredRatingView(viewModel: viewModel)
        }
        .onChange(of: appNav?.shouldDismissCookingFlow) { _, newValue in
            if newValue == true {
                dismiss()  // Pop back to Home root
            }
        }
    }

    // MARK: - Scale Label
    private var scaleLabel: String {
        let cat = viewModel.category
        if viewModel.scaleMultiplier == 1.0 {
            return "1 \(cat.unitLabel)"
        }
        let m = viewModel.scaleMultiplier
        let formatted = m.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(m))" : String(format: "%.1f", m)
        return "\(formatted) \(cat.unitLabel)\(m != 1 ? "s" : "")"
    }

    // MARK: - Scale Picker
    private var scalePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Theme.premiumIcon("scalemass.fill", color: Theme.primary)
                Text("ADJUST QUANTITY")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("Base: 1 \(viewModel.category.unitLabel)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }

            // Preset buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.category.presets, id: \.multiplier) { preset in
                        Button(action: {
                            withAnimation { viewModel.scaleMultiplier = preset.multiplier }
                        }) {
                            Text(preset.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(viewModel.scaleMultiplier == preset.multiplier ? .white : Theme.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(viewModel.scaleMultiplier == preset.multiplier ? Theme.primary : Theme.primaryLight)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Custom input
            HStack(spacing: 8) {
                TextField("Custom (e.g. 10)", text: $viewModel.customQuantityText)
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.primaryLight, lineWidth: 1)
                    )

                Button(action: {
                    viewModel.applyCustomQuantity()
                }) {
                    Text("Apply")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.primary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
    }

    // MARK: - Suggestions
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Theme.premiumIcon("exclamationmark.triangle.fill", color: Theme.accent)
                Text("Improvement Suggestions")
                    .font(Theme.bodyFont().weight(.bold))
                Spacer()
                Theme.premiumIcon("info.circle.fill", color: Theme.textSecondary)
            }

            ForEach(viewModel.recipe.latestSuggestions, id: \.self) { suggestion in
                HStack(spacing: 8) {
                    Circle().fill(Theme.accent).frame(width: 6, height: 6)
                    Text(suggestion)
                        .font(Theme.bodyFont())
                        .foregroundColor(Theme.textMain)
                }
            }
        }
        .padding(20)
        .background(Theme.accent.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Time Estimate
    private var timeEstimateSection: some View {
        let totalTime = HeatOptimizer.estimateTotalTime(steps: viewModel.recipe.sortedSteps)
        let optimizableSteps = HeatOptimizer.optimizableSteps(from: viewModel.recipe.sortedSteps)
        let timeSaved = optimizableSteps.reduce(0) { total, item in
            viewModel.optimizedStepIds.contains(item.step.order)
                ? total + (item.originalDuration - item.optimizedDuration)
                : total
        }
        let displayTime = totalTime - timeSaved

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Theme.premiumIcon("clock.fill", color: Theme.primary)
                Text("ESTIMATED TIME")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                Spacer()

                Text(HeatOptimizer.formatTime(displayTime))
                    .font(Theme.titleFont(size: 18))
                    .foregroundColor(Theme.textMain)
            }

            if timeSaved > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                    Text("Saving \(HeatOptimizer.formatTime(timeSaved))")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Theme.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.success.opacity(0.12))
                .clipShape(Capsule())
            }

            // Optimize button
            if !optimizableSteps.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showingOptimizer.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 18))
                        Text("Optimize Cooking Time")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        Image(systemName: viewModel.showingOptimizer ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        LinearGradient(colors: [Color(hex: "EF4444"), Theme.accent], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
                }

                // Optimizable steps list
                if viewModel.showingOptimizer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select steps to speed up with higher heat:")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)

                        ForEach(optimizableSteps, id: \.step.order) { item in
                            let isOptimized = viewModel.optimizedStepIds.contains(item.step.order)
                            let saving = item.originalDuration - item.optimizedDuration

                            Button(action: {
                                if isOptimized {
                                    viewModel.optimizedStepIds.remove(item.step.order)
                                } else {
                                    viewModel.optimizedStepIds.insert(item.step.order)
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: isOptimized ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isOptimized ? Theme.success : Theme.textSecondary.opacity(0.4))
                                        .font(.system(size: 20))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.step.instruction)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Theme.textMain)
                                            .lineLimit(2)

                                        HStack(spacing: 8) {
                                            HStack(spacing: 3) {
                                                Image(systemName: "flame")
                                                    .font(.system(size: 9))
                                                Text(item.action.label)
                                                    .font(.system(size: 10, weight: .medium))
                                            }
                                            .foregroundColor(Theme.accent)

                                            if isOptimized {
                                                HStack(spacing: 3) {
                                                    Text(HeatOptimizer.formatTime(item.originalDuration))
                                                        .strikethrough()
                                                    Text("→ \(HeatOptimizer.formatTime(item.optimizedDuration))")
                                                }
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(Theme.success)
                                            } else {
                                                Text(HeatOptimizer.formatTime(item.originalDuration))
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(Theme.textSecondary)
                                            }

                                            if saving > 0 {
                                                Text("-\(HeatOptimizer.formatTime(saving))")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(Color(hex: "EF4444"))
                                            }
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(12)
                                .background(isOptimized ? Theme.success.opacity(0.06) : Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isOptimized ? Theme.success.opacity(0.3) : Theme.primaryLight.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showingOptimizer)
        .animation(.easeInOut(duration: 0.2), value: viewModel.optimizedStepIds)
    }

    // MARK: - Ingredients
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Theme.premiumIcon("checklist", color: Theme.primary)
                Text("INGREDIENT CHECKLIST")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                if viewModel.scaleMultiplier != 1.0 {
                    Text("×\(viewModel.scaleMultiplier.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(viewModel.scaleMultiplier))" : String(format: "%.1f", viewModel.scaleMultiplier))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)

            if viewModel.hasIngredients {
                ForEach(viewModel.recipe.ingredients) { ingredient in
                    IngredientCheckRow(
                        ingredient: ingredient,
                        scaledQuantity: viewModel.scaledQuantity(for: ingredient),
                        isChecked: viewModel.isIngredientChecked(ingredient.persistentModelID)
                    ) {
                        viewModel.toggleIngredient(ingredient.persistentModelID)
                    }
                }
                .padding(.horizontal)
            } else {
                Text("No ingredients yet. Tap + to add manually.")
                    .font(Theme.bodyFont())
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal)
                    .italic()
            }

            // Add Ingredient
            if viewModel.showingAddIngredient {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        TextField("Ingredient name", text: $viewModel.newIngredientName)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.primary, lineWidth: 1.5)
                            )

                        TextField("Qty (e.g. 2 cups)", text: $viewModel.newIngredientQuantity)
                            .padding(10)
                            .frame(width: 130)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.primaryLight, lineWidth: 1)
                            )
                    }

                    HStack(spacing: 12) {
                        Button(action: { viewModel.addIngredient() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("Add")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Theme.primary)
                            .clipShape(Capsule())
                        }
                        .disabled(viewModel.newIngredientName.trimmingCharacters(in: .whitespaces).isEmpty)

                        Button(action: {
                            withAnimation { viewModel.showingAddIngredient = false }
                            viewModel.newIngredientName = ""
                            viewModel.newIngredientQuantity = ""
                        }) {
                            Text("Cancel")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showingAddIngredient = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add Ingredient")
                            .font(Theme.bodyFont(size: 14).weight(.semibold))
                    }
                    .foregroundColor(Theme.primary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Theme.primaryLight.opacity(0.3))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Steps
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Theme.premiumIcon("text.badge.checkmark", color: Theme.primary)
                Text("STEPS PREVIEW")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal)

            ForEach(Array(viewModel.recipe.sortedSteps.enumerated()), id: \.element.id) { index, step in
                let action = IngredientExtractor.detectCookingAction(from: step.instruction)
                let ingredientEmoji = IngredientEmojiMapper.findIngredientEmoji(in: step.instruction)

                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 6) {
                        Text("\(index + 1)")
                            .font(Theme.bodyFont(size: 14).weight(.bold))
                            .foregroundColor(Theme.primary)
                            .frame(width: 28, height: 28)
                            .background(Theme.primaryLight)
                            .clipShape(Circle())

                        // Ingredient emoji or action emoji
                        Text(ingredientEmoji ?? action.emoji)
                            .font(.system(size: 20))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(step.instruction)
                            .font(Theme.bodyFont())
                            .foregroundColor(Theme.textMain)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            Image(systemName: action.icon)
                                .font(.system(size: 10))
                            Text(action.label)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(14)
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 120)
    }
}

// MARK: - Ingredient Row
struct IngredientCheckRow: View {
    let ingredient: Ingredient
    let scaledQuantity: String
    let isChecked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Theme.premiumIcon(isChecked ? "checkmark.circle.fill" : "circle", color: isChecked ? Theme.primary : Theme.textSecondary)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 3) {
                    Text(ingredient.name)
                        .font(Theme.bodyFont())
                        .strikethrough(isChecked)
                        .foregroundColor(isChecked ? Theme.textSecondary : Theme.textMain)

                    Text(scaledQuantity)
                        .font(Theme.bodyFont(size: 13))
                        .foregroundColor(Theme.primary.opacity(0.8))
                }

                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Deferred Rating
struct DeferredRatingView: View {
    @Bindable var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.dismissDeferredRating()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Text("How was your last time cooking **\(viewModel.recipe.name)**?")
                    .font(Theme.titleFont(size: 24))

                VStack(alignment: .leading, spacing: 12) {
                    Text("RATING")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textSecondary)

                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= viewModel.deferredRating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundColor(star <= viewModel.deferredRating ? Theme.accent : Theme.textSecondary.opacity(0.3))
                                .onTapGesture {
                                    viewModel.deferredRating = star
                                }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("NOTES & OBSERVATIONS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textSecondary)

                    TextEditor(text: $viewModel.deferredNotes)
                        .padding(10)
                        .frame(height: 120)
                        .scrollContentBackground(.hidden)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.primaryLight, lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if viewModel.deferredNotes.isEmpty {
                                    Text("e.g. Too salty, slightly overcooked...")
                                        .padding(15)
                                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                                        .font(Theme.bodyFont())
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }

                Spacer()

                PrimaryButton(title: "Submit Rating") {
                    viewModel.submitDeferredRating()
                    dismiss()
                }
                .disabled(viewModel.deferredRating == 0)
                .opacity(viewModel.deferredRating == 0 ? 0.5 : 1)
            }
            .padding(24)
            .background(Theme.background)
        }
        .presentationDetents([.large])
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: Recipe.sample)
    }
    .modelContainer(for: Recipe.self, inMemory: true)
}
