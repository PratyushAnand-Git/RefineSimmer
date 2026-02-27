import SwiftUI
import SwiftData

struct GuidedCookingView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("RS_UserGender") private var userGender: String = "female"
    @State private var viewModel: CookingViewModel
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(recipe: Recipe) {
        _viewModel = State(initialValue: CookingViewModel(recipe: recipe))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Theme.premiumIcon("xmark.circle.fill", color: Theme.textMain)
                            .font(.system(size: 24))
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text("Cooking Session")
                            .font(Theme.bodyFont(size: 12).weight(.bold))
                            .foregroundColor(Theme.textSecondary)
                        Text(viewModel.recipe.name)
                            .font(Theme.bodyFont(size: 16).weight(.bold))
                            .foregroundColor(Theme.textMain)
                    }
                    Spacer()
                    Button(action: { viewModel.showingStepExplainer = true }) {
                        Theme.premiumIcon("questionmark.circle.fill", color: Theme.textSecondary)
                            .font(.system(size: 24))
                    }
                }
                .padding()
                .background(Color.white)

                // Progress bar
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.primaryLight.opacity(0.3))
                        .frame(height: 6)
                    Rectangle()
                        .fill(Theme.primary)
                        .frame(width: geometry.size.width * viewModel.progress, height: 6)
                        .animation(.spring(), value: viewModel.progress)
                }

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: 16)

                        // Step badge
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Theme.premiumIcon("list.bullet.indent", color: Theme.primary)
                                Text("STEP \(viewModel.currentStepIndex + 1) OF \(viewModel.stepCount)")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.primaryLight)
                            .clipShape(Capsule())

                            // Cooking action badge
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.currentAction.icon)
                                    .font(.system(size: 12))
                                Text(viewModel.currentAction.label)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Theme.accent.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        // Animated avatar
                        CookingAvatarView(
                            action: viewModel.currentAction,
                            stepInstruction: viewModel.currentStep.instruction,
                            isMale: userGender == "male"
                        )
                        .frame(height: 160)
                        .id(viewModel.currentStepIndex)

                        // Step instruction
                        Text(viewModel.currentStep.instruction)
                            .font(Theme.titleFont(size: 24))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .minimumScaleFactor(0.6)

                        // Timer section
                        if viewModel.effectiveDuration != nil {
                            VStack(spacing: 14) {
                                HStack(spacing: 12) {
                                    Theme.premiumIcon("timer.circle.fill", color: viewModel.isTimerRunning ? Theme.accent : Theme.textSecondary)
                                        .font(.system(size: 40))

                                    Text(viewModel.timeString)
                                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textMain)
                                }

                                HStack(spacing: 12) {
                                    Button(action: { viewModel.toggleTimer() }) {
                                        HStack {
                                            Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                                            Text(viewModel.isTimerRunning ? "Pause" : "Start")
                                        }
                                        .font(Theme.bodyFont(size: 15).weight(.bold))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 11)
                                        .background(viewModel.isTimerRunning ? Theme.primary : Theme.accent)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                    }

                                    Button(action: { viewModel.addOneMinute() }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 12, weight: .bold))
                                            Text("1 min")
                                                .font(Theme.bodyFont(size: 14).weight(.bold))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 11)
                                        .background(Theme.primaryLight)
                                        .foregroundColor(Theme.primary)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(24)
                            .background(Theme.background)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 100)
                    }
                }

                // Navigation buttons
                VStack(spacing: 0) {
                    HStack(spacing: 20) {
                        if viewModel.currentStepIndex > 0 {
                            Button(action: { viewModel.previousStep() }) {
                                Theme.premiumIcon("arrow.left.circle.fill", color: Theme.primary)
                                    .font(.system(size: 60))
                                    .background(Circle().fill(.white))
                            }
                        }

                        PrimaryButton(title: viewModel.isLastStep ? "Finish Cooking" : "Next Step") {
                            viewModel.nextStep()
                        }
                        .frame(height: 70)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Next step preview line
                    nextStepPreviewLine
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 34)
                }
                .background(Color.white.shadow(color: .black.opacity(0.03), radius: 5, y: -3))
            }
        }
        .background(Color.white)
        .onReceive(timer) { _ in
            viewModel.updateTimer()
        }
        .fullScreenCover(isPresented: $viewModel.showingReview) {
            PostCookingReviewView(recipe: viewModel.recipe)
        }
        .sheet(isPresented: $viewModel.showingStepExplainer) {
            StepExplainerSheet(viewModel: viewModel)
        }
    }

    // MARK: - Next Step Preview
    private var nextStepPreviewLine: some View {
        Group {
            if viewModel.isLastStep {
                // Last step — congratulations
                HStack(spacing: 8) {
                    Text("🎉")
                        .font(.system(size: 16))
                    Text("Congrats, it's the last step!")
                        .font(Theme.bodyFont(size: 13).weight(.semibold))
                        .foregroundColor(Theme.success)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Theme.success.opacity(0.1))
                .clipShape(Capsule())
            } else if let preview = viewModel.nextStepPreview,
                      let action = viewModel.nextStepAction {
                VStack(spacing: 6) {
                    // Connector line
                    Rectangle()
                        .fill(Theme.primaryLight)
                        .frame(width: 2, height: 12)

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.primary.opacity(0.5))

                        Text("Up next:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSecondary)

                        let emoji = IngredientEmojiMapper.findIngredientEmoji(in: preview)
                        Text(emoji ?? action.emoji)
                            .font(.system(size: 14))

                        Text(preview)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textMain.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(Theme.background)
                    .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Step Explainer Sheet
struct StepExplainerSheet: View {
    let viewModel: CookingViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Step reference
                    VStack(spacing: 8) {
                        Text("Step \(viewModel.currentStepIndex + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textSecondary)

                        Text(viewModel.currentStep.instruction)
                            .font(Theme.titleFont(size: 20))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primaryLight.opacity(0.3))
                    .cornerRadius(16)

                    // How-To
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "book.fill")
                                .foregroundColor(Theme.primary)
                            Text("HOW TO DO THIS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                        }

                        Text(viewModel.currentExplanation.howTo)
                            .font(Theme.bodyFont())
                            .foregroundColor(Theme.textMain)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.03), radius: 6, y: 3)

                    // Pro Tips
                    if !viewModel.currentExplanation.proTips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(Theme.accent)
                                Text("PRO TIPS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.textSecondary)
                            }

                            ForEach(viewModel.currentExplanation.proTips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(Theme.accent)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 7)

                                    Text(tip)
                                        .font(Theme.bodyFont(size: 14))
                                        .foregroundColor(Theme.textMain)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(16)
                        .background(Theme.accent.opacity(0.08))
                        .cornerRadius(14)
                    }

                    // Ingredients in this step
                    if !viewModel.currentExplanation.ingredientsNeeded.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "checklist")
                                    .foregroundColor(Theme.success)
                                Text("INGREDIENTS IN THIS STEP")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.textSecondary)
                            }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                                ForEach(viewModel.currentExplanation.ingredientsNeeded, id: \.self) { ingredient in
                                    let emoji = IngredientEmojiMapper.findIngredientEmoji(in: ingredient.lowercased())
                                    HStack(spacing: 6) {
                                        Text(emoji ?? "🧂")
                                            .font(.system(size: 16))
                                        Text(ingredient)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Theme.textMain)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Theme.success.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
                    }
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle("Step Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    GuidedCookingView(recipe: Recipe.sample)
        .modelContainer(for: Recipe.self, inMemory: true)
}
