import SwiftUI
import Observation

@Observable
class CookingViewModel {
    let recipe: Recipe
    var currentStepIndex: Int = 0
    var timeRemaining: Int = 0
    var isTimerRunning: Bool = false
    var showingReview: Bool = false
    var showingStepExplainer: Bool = false

    init(recipe: Recipe) {
        self.recipe = recipe
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

    var effectiveDuration: Int? {
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

    func nextStep() {
        if currentStepIndex < stepCount - 1 {
            currentStepIndex += 1
            resetTimer()
        } else {
            showingReview = true
        }
    }

    func previousStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            resetTimer()
        }
    }

    func toggleTimer() {
        if isTimerRunning {
            isTimerRunning = false
        } else if let duration = effectiveDuration {
            if timeRemaining == 0 {
                timeRemaining = duration
            }
            isTimerRunning = true
        }
    }

    func addOneMinute() {
        timeRemaining += 60
    }

    func resetTimer() {
        isTimerRunning = false
        timeRemaining = 0
    }

    func updateTimer() {
        if isTimerRunning && timeRemaining > 0 {
            timeRemaining -= 1
        } else if timeRemaining == 0 {
            isTimerRunning = false
        }
    }

    var timeString: String {
        let displayTime = (isTimerRunning || timeRemaining > 0) ? timeRemaining : (effectiveDuration ?? 0)
        let m = displayTime / 60
        let s = displayTime % 60
        return String(format: "%02d:%02d", m, s)
    }
}
