import SwiftUI
import Observation

@Observable
class CookingViewModel {
    let recipe: Recipe
    let optimizedStepIds: Set<Int>  // Step order indices selected for high-heat optimization
    var currentStepIndex: Int = 0
    var timeRemaining: Int = 0
    var isTimerRunning: Bool = false
    var showingReview: Bool = false
    var showingStepExplainer: Bool = false

    // Heat optimization
    var showingHeatOptions: Bool = false
    var currentHeatLevel: HeatLevel = .low
    var elapsedOnCurrentHeat: Int = 0
    private var originalDurationForStep: Int = 0

    // Voice assistant
    let voice = VoiceCookingAssistant()

    init(recipe: Recipe, optimizedStepIds: Set<Int> = []) {
        self.recipe = recipe
        self.optimizedStepIds = optimizedStepIds

        // When voice finishes reading a step, auto-start the timer (if step has one)
        voice.onStepAnnouncementCompleted = { [weak self] in
            guard let self else { return }
            if self.effectiveDuration != nil && !self.isTimerRunning {
                // Set timer duration and start
                if self.timeRemaining == 0 {
                    self.timeRemaining = self.effectiveDuration ?? 0
                }
                self.isTimerRunning = true
            }
        }

        // Announce first step after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.announceCurrentStep()
        }
    }

    /// Ask voice to announce the current step
    private func announceCurrentStep() {
        voice.announceStep(
            index: currentStepIndex,
            instruction: currentStep.instruction,
            action: currentAction,
            durationSeconds: effectiveDuration
        )
    }

    var currentExplanation: StepExplainer.Explanation {
        StepExplainer.explain(currentStep.instruction)
    }

    var currentStep: Step {
        recipe.sortedSteps[currentStepIndex]
    }

    var stepCount: Int {
        recipe.steps.count
    }

    var progress: Double {
        guard stepCount > 0 else { return 0 }
        return Double(currentStepIndex + 1) / Double(stepCount)
    }

    var currentAction: CookingAction {
        IngredientExtractor.detectCookingAction(from: currentStep.instruction)
    }

    /// Returns optimized duration if the step was selected for optimization
    var effectiveDuration: Int? {
        let baseDuration = currentStep.durationSeconds ?? IngredientExtractor.suggestDuration(for: currentAction)
        guard let duration = baseDuration, duration > 0 else { return baseDuration }

        // If this step was checked for high-heat optimization, use optimized time
        if optimizedStepIds.contains(currentStep.order) {
            let highTime = Int(ceil(Double(duration) * HeatLevel.high.timeMultiplier / HeatLevel.low.timeMultiplier))
            return max(highTime, 30)
        }
        return duration
    }

    /// Whether the current step is pre-optimized from the recipe detail screen
    var isCurrentStepOptimized: Bool {
        optimizedStepIds.contains(currentStep.order)
    }

    /// Raw base duration (always original low-heat time, ignoring optimization)
    var rawBaseDuration: Int? {
        currentStep.durationSeconds ?? IngredientExtractor.suggestDuration(for: currentAction)
    }

    var isLastStep: Bool {
        currentStepIndex == stepCount - 1
    }

    var nextStepPreview: String? {
        guard !isLastStep else { return nil }
        return recipe.sortedSteps[currentStepIndex + 1].instruction
    }

    var nextStepAction: CookingAction? {
        guard let preview = nextStepPreview else { return nil }
        return IngredientExtractor.detectCookingAction(from: preview)
    }

    // MARK: - Heat Optimization

    /// Can the current step be heat-optimized?
    var canOptimizeCurrentStep: Bool {
        guard effectiveDuration != nil else { return false }
        return HeatOptimizer.canOptimize(action: currentAction)
    }

    /// Get heat options for the current step
    var heatOptions: [HeatOptimizer.HeatOption] {
        guard let baseDuration = rawBaseDuration else { return [] }

        if elapsedOnCurrentHeat > 0 {
            // Calculate remaining time on each heat level accounting for elapsed time
            let totalOnCurrent = originalDurationForStep > 0 ? originalDurationForStep : (effectiveDuration ?? baseDuration)
            return HeatLevel.allCases.map { level in
                let remaining = HeatOptimizer.remainingTime(
                    elapsed: elapsedOnCurrentHeat,
                    totalOnCurrent: totalOnCurrent,
                    currentHeat: currentHeatLevel,
                    targetHeat: level
                )
                return HeatOptimizer.HeatOption(
                    heatLevel: level,
                    durationSeconds: remaining,
                    isSafe: !(level == .high && currentAction == .simmer),
                    warning: level == .high && currentAction == .simmer ? "May affect texture" : nil
                )
            }
        } else {
            // Use the raw base duration (low-heat) so the optimizer calculates all levels correctly
            return HeatOptimizer.heatOptions(baseDurationSeconds: baseDuration, action: currentAction)
        }
    }

    /// Total estimated time for the recipe
    var totalEstimatedTime: Int {
        HeatOptimizer.estimateTotalTime(steps: recipe.sortedSteps)
    }

    /// Optimized total time (high heat where possible)
    var optimizedEstimatedTime: Int {
        HeatOptimizer.estimateOptimizedTime(steps: recipe.sortedSteps)
    }

    /// Time saved if fully optimized
    var timeSaved: Int {
        totalEstimatedTime - optimizedEstimatedTime
    }

    // MARK: - Heat Switching

    /// Switch heat level mid-step — recalculates remaining timer
    func switchHeat(to level: HeatLevel) {
        guard let duration = effectiveDuration else { return }

        // Stop voice immediately on heat change
        voice.stopSpeaking()

        // Calculate elapsed time on current heat
        let totalForStep = originalDurationForStep > 0 ? originalDurationForStep : duration
        let elapsed = totalForStep - timeRemaining
        elapsedOnCurrentHeat = max(elapsed, 0)

        // Track the original duration for future calculations
        if originalDurationForStep == 0 {
            originalDurationForStep = duration
        }

        // Calculate remaining time on new heat level
        let remaining = HeatOptimizer.remainingTime(
            elapsed: elapsedOnCurrentHeat,
            totalOnCurrent: totalForStep,
            currentHeat: currentHeatLevel,
            targetHeat: level
        )

        currentHeatLevel = level
        timeRemaining = remaining

        showingHeatOptions = false

        // Announce heat change with new time
        voice.announceHeatChange(newHeat: level, newRemainingSeconds: remaining)
    }

    // MARK: - Auto-Advance

    /// Countdown before auto-advancing (10 → 0)
    var autoAdvanceCountdown: Int = 0
    var isAutoAdvancing: Bool = false

    /// Cancel the auto-advance countdown
    func cancelAutoAdvance() {
        isAutoAdvancing = false
        autoAdvanceCountdown = 0
    }

    // MARK: - Navigation

    func nextStep() {
        cancelAutoAdvance()
        voice.stopSpeaking()
        if currentStepIndex < stepCount - 1 {
            currentStepIndex += 1
            resetTimer()
            announceCurrentStep()
        } else {
            showingReview = true
        }
    }

    func previousStep() {
        cancelAutoAdvance()
        voice.stopSpeaking()
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            resetTimer()
            announceCurrentStep()
        }
    }

    func toggleTimer() {
        cancelAutoAdvance()
        if isTimerRunning {
            isTimerRunning = false
            voice.stopSpeaking()  // Stop voice on pause
        } else if let duration = effectiveDuration {
            if timeRemaining == 0 {
                timeRemaining = duration
            }
            isTimerRunning = true
        }
    }

    func addOneMinute() {
        cancelAutoAdvance()
        timeRemaining += 60
    }

    func resetTimer() {
        isTimerRunning = false
        timeRemaining = 0
        // Auto-set high heat for pre-optimized steps
        currentHeatLevel = isCurrentStepOptimized ? .high : .low
        elapsedOnCurrentHeat = 0
        originalDurationForStep = 0
        showingHeatOptions = false
        cancelAutoAdvance()
        voice.resetForStep()
    }

    func updateTimer() {
        if isTimerRunning && timeRemaining > 0 {
            timeRemaining -= 1

            // Voice timer alerts (10s, 1min, hints, completion)
            voice.timerTick(
                stepIndex: currentStepIndex,
                timeRemaining: timeRemaining,
                totalDuration: effectiveDuration ?? 0,
                isTimerRunning: true,
                action: currentAction
            )

            if timeRemaining == 0 {
                isTimerRunning = false
                // Start 10-second auto-advance countdown
                if !isLastStep {
                    isAutoAdvancing = true
                    autoAdvanceCountdown = 10
                }
            }
        } else if isAutoAdvancing && autoAdvanceCountdown > 0 {
            autoAdvanceCountdown -= 1
            if autoAdvanceCountdown == 0 {
                isAutoAdvancing = false
                nextStep()
            }
        }
    }

    var timeString: String {
        let displayTime = (isTimerRunning || timeRemaining > 0) ? timeRemaining : (effectiveDuration ?? 0)
        let m = displayTime / 60
        let s = displayTime % 60
        return String(format: "%02d:%02d", m, s)
    }
}

