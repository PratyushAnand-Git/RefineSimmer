import SwiftUI
import SwiftData

struct GuidedCookingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppNavigation.self) private var appNav: AppNavigation?
    @AppStorage("RS_UserGender") private var userGender: String = "female"
    @State private var viewModel: CookingViewModel
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(recipe: Recipe, optimizedStepIds: Set<Int> = []) {
        _viewModel = State(initialValue: CookingViewModel(recipe: recipe, optimizedStepIds: optimizedStepIds))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        viewModel.voice.stopSpeaking()
                        dismiss()
                    }) {
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

                    // Voice toggle
                    Button(action: {
                        viewModel.voice.isEnabled.toggle()
                        if !viewModel.voice.isEnabled {
                            viewModel.voice.stopSpeaking()
                        }
                    }) {
                        Image(systemName: viewModel.voice.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.voice.isEnabled ? Theme.primary : Theme.textSecondary)
                    }
                    .padding(.trailing, 8)

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

                // Main content — fills available space, NO scrolling
                VStack(spacing: 0) {
                    Spacer(minLength: 4)

                    // Step badge + action badge
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Theme.premiumIcon("list.bullet.indent", color: Theme.primary)
                                .font(.system(size: 12))
                            Text("STEP \(viewModel.currentStepIndex + 1) OF \(viewModel.stepCount)")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Theme.primaryLight)
                        .clipShape(Capsule())

                        HStack(spacing: 5) {
                            Image(systemName: viewModel.currentAction.icon)
                                .font(.system(size: 11))
                            Text(viewModel.currentAction.label)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    Spacer(minLength: 4)

                    // Avatar
                    CookingAvatarView(
                        action: viewModel.currentAction,
                        stepInstruction: viewModel.currentStep.instruction,
                        isMale: userGender == "male"
                    )
                    .frame(height: 90)
                    .id(viewModel.currentStepIndex)

                    Spacer(minLength: 4)

                    // Instruction text
                    Text(viewModel.currentStep.instruction)
                        .font(Theme.titleFont(size: 18))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .minimumScaleFactor(0.6)
                        .lineLimit(3)

                    Spacer(minLength: 6)

                    // Timer section
                    if viewModel.effectiveDuration != nil {
                        VStack(spacing: 8) {
                            if viewModel.canOptimizeCurrentStep {
                                HStack(spacing: 6) {
                                    Image(systemName: viewModel.currentHeatLevel.icon)
                                        .font(.system(size: 12))
                                    Text(viewModel.currentHeatLevel.label)
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(Color(hex: viewModel.currentHeatLevel.color))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color(hex: viewModel.currentHeatLevel.color).opacity(0.12))
                                .clipShape(Capsule())
                            }

                            HStack(spacing: 8) {
                                Theme.premiumIcon("timer.circle.fill", color: viewModel.isTimerRunning ? Theme.accent : Theme.textSecondary)
                                    .font(.system(size: 26))
                                Text(viewModel.timeString)
                                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textMain)
                            }

                            HStack(spacing: 10) {
                                Button(action: { viewModel.toggleTimer() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                                            .font(.system(size: 12))
                                        Text(viewModel.isTimerRunning ? "Pause" : "Start")
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(viewModel.isTimerRunning ? Theme.primary : Theme.accent)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                }

                                Button(action: { viewModel.addOneMinute() }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                        Text("1 min")
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(Theme.primaryLight)
                                    .foregroundColor(Theme.primary)
                                    .clipShape(Capsule())
                                }

                                if viewModel.canOptimizeCurrentStep {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.showingHeatOptions.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 3) {
                                            Image(systemName: "bolt.fill")
                                                .font(.system(size: 10, weight: .bold))
                                            Text("Heat")
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .background(viewModel.showingHeatOptions ? Theme.accent : Color(hex: "FEE2E2"))
                                        .foregroundColor(viewModel.showingHeatOptions ? .white : Color(hex: "EF4444"))
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            if viewModel.showingHeatOptions {
                                heatOptionsPanel
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            if viewModel.isAutoAdvancing {
                                HStack(spacing: 8) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 12))
                                    Text("Next step in \(viewModel.autoAdvanceCountdown)s")
                                        .font(.system(size: 13, weight: .bold))
                                    Spacer()
                                    Button(action: { viewModel.cancelAutoAdvance() }) {
                                        Text("Cancel")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Theme.accent)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.white)
                                            .clipShape(Capsule())
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Theme.accent.opacity(0.9))
                                .cornerRadius(10)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(16)
                        .background(Theme.background)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                        .padding(.horizontal, 16)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.showingHeatOptions)
                    }

                    Spacer(minLength: 6)

                    // Navigation buttons
                    VStack(spacing: 6) {
                        HStack(spacing: 16) {
                            if viewModel.currentStepIndex > 0 {
                                Button(action: { viewModel.previousStep() }) {
                                    Theme.premiumIcon("arrow.left.circle.fill", color: Theme.primary)
                                        .font(.system(size: 44))
                                        .background(Circle().fill(.white))
                                }
                            }

                            PrimaryButton(title: viewModel.isLastStep ? "Finish Cooking" : "Next Step") {
                                viewModel.nextStep()
                            }
                            .frame(height: 54)
                        }
                        .padding(.horizontal, 24)

                        nextStepPreviewLine
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                    }
                    .background(Color.white.shadow(color: .black.opacity(0.03), radius: 5, y: -3))
                }
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
        .onChange(of: appNav?.shouldDismissCookingFlow) { _, newValue in
            if newValue == true {
                dismiss()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isAutoAdvancing)
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

    // MARK: - Heat Options Panel
    private var heatOptionsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.accent)
                Text("SWITCH HEAT LEVEL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
            }

            ForEach(viewModel.heatOptions) { option in
                let isSelected = option.heatLevel == viewModel.currentHeatLevel
                let levelColor = Color(hex: option.heatLevel.color)

                Button(action: { viewModel.switchHeat(to: option.heatLevel) }) {
                    HStack(spacing: 10) {
                        Image(systemName: option.heatLevel.icon)
                            .font(.system(size: 16))
                            .foregroundColor(levelColor)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.heatLevel.label)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isSelected ? levelColor : Theme.textMain)

                            if let warning = option.warning {
                                Text(warning)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "EF4444"))
                            }
                        }

                        Spacer()

                        Text(HeatOptimizer.formatTime(option.durationSeconds))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(isSelected ? levelColor : Theme.textMain)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(levelColor)
                                .font(.system(size: 16))
                        }
                    }
                    .padding(12)
                    .background(isSelected ? levelColor.opacity(0.1) : Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? levelColor : Color.clear, lineWidth: 1.5)
                    )
                }
                .disabled(!option.isSafe)
                .opacity(option.isSafe ? 1 : 0.5)
            }
        }
        .padding(.top, 6)
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
