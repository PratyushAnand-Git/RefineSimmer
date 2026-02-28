import Foundation

/// Heat level optimization engine
/// Converts cooking times between heat levels using empirical ratios
/// Low 10 min ≈ Medium 6 min ≈ High 2 min (ratio 5:3:1)
enum HeatLevel: String, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: return "Low Flame"
        case .medium: return "Medium Flame"
        case .high: return "High Flame"
        }
    }

    var shortLabel: String {
        switch self {
        case .low: return "🔵 Low"
        case .medium: return "🟠 Medium"
        case .high: return "🔴 High"
        }
    }

    var icon: String {
        switch self {
        case .low: return "flame"
        case .medium: return "flame.fill"
        case .high: return "flame.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .low: return "4A9EFF"    // Blue
        case .medium: return "F59E0B" // Amber
        case .high: return "EF4444"   // Red
        }
    }

    /// Base multiplier relative to low flame (low = 1.0)
    var timeMultiplier: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 0.6
        case .high: return 0.2
        }
    }
}

struct HeatOptimizer {

    /// A time option showing heat level and duration
    struct HeatOption: Identifiable {
        let id = UUID()
        let heatLevel: HeatLevel
        let durationSeconds: Int
        let isSafe: Bool          // false if overheating risk
        let warning: String?      // e.g. "May affect texture"
    }

    /// Actions that can be optimized with heat
    private static let heatOptimizableActions: Set<CookingAction> = [
        .boil, .simmer, .fry, .stirFry, .heat, .cook, .steam
    ]

    /// Actions where high heat is risky
    private static let highHeatRisky: Set<CookingAction> = [
        .simmer  // Simmering at high heat changes texture/flavor
    ]

    /// Actions that CANNOT be heat-optimized
    private static let nonOptimizable: Set<CookingAction> = [
        .bake, .rest, .prep, .mix, .pour, .serve, .coat, .knead, .flip, .general, .grill
    ]

    /// Check if a step can be heat-optimized
    static func canOptimize(action: CookingAction) -> Bool {
        heatOptimizableActions.contains(action)
    }

    /// Get all heat options for a step's base duration
    /// baseDuration is assumed to be at low heat
    static func heatOptions(baseDurationSeconds: Int, action: CookingAction, baseHeat: HeatLevel = .low) -> [HeatOption] {
        // Normalize to low-heat equivalent first
        let lowEquivalent = Double(baseDurationSeconds) / baseHeat.timeMultiplier

        return HeatLevel.allCases.map { level in
            let scaledDuration = Int(ceil(lowEquivalent * level.timeMultiplier))

            let isSafe: Bool
            let warning: String?

            if level == .high && highHeatRisky.contains(action) {
                isSafe = false
                warning = "High heat may affect texture"
            } else if level == .high && action == .cook {
                isSafe = true
                warning = "Watch closely to avoid burning"
            } else {
                isSafe = true
                warning = nil
            }

            return HeatOption(
                heatLevel: level,
                durationSeconds: max(scaledDuration, 30), // Minimum 30 seconds
                isSafe: isSafe,
                warning: warning
            )
        }
    }

    /// Calculate remaining time on a different heat level after partial cooking
    /// - elapsed: seconds already cooked on currentHeat
    /// - totalOnCurrent: total seconds that were planned on currentHeat
    /// - targetHeat: the new heat level to switch to
    static func remainingTime(
        elapsed: Int,
        totalOnCurrent: Int,
        currentHeat: HeatLevel,
        targetHeat: HeatLevel
    ) -> Int {
        let remaining = totalOnCurrent - elapsed
        guard remaining > 0 else { return 0 }

        // Convert remaining time to low-heat equivalent
        let lowEquivalent = Double(remaining) / currentHeat.timeMultiplier

        // Convert to target heat
        let targetTime = Int(ceil(lowEquivalent * targetHeat.timeMultiplier))
        return max(targetTime, 15) // Minimum 15 seconds
    }

    /// Estimate total cooking time for a recipe
    static func estimateTotalTime(steps: [Step]) -> Int {
        steps.reduce(0) { total, step in
            let action = IngredientExtractor.detectCookingAction(from: step.instruction)
            let duration = step.durationSeconds ?? IngredientExtractor.suggestDuration(for: action) ?? 0
            return total + duration
        }
    }

    /// Estimate optimized total time (all optimizable steps on high heat)
    static func estimateOptimizedTime(steps: [Step]) -> Int {
        steps.reduce(0) { total, step in
            let action = IngredientExtractor.detectCookingAction(from: step.instruction)
            let duration = step.durationSeconds ?? IngredientExtractor.suggestDuration(for: action) ?? 0

            if canOptimize(action: action) && duration > 0 {
                // Convert to high heat equivalent
                let highTime = Int(ceil(Double(duration) * HeatLevel.high.timeMultiplier / HeatLevel.low.timeMultiplier))
                return total + max(highTime, 30)
            }
            return total + duration
        }
    }

    /// Get list of steps that can be optimized with time savings
    static func optimizableSteps(from steps: [Step]) -> [(step: Step, originalDuration: Int, optimizedDuration: Int, action: CookingAction)] {
        steps.compactMap { step in
            let action = IngredientExtractor.detectCookingAction(from: step.instruction)
            let duration = step.durationSeconds ?? IngredientExtractor.suggestDuration(for: action) ?? 0

            guard canOptimize(action: action) && duration > 60 else { return nil }

            let highTime = Int(ceil(Double(duration) * HeatLevel.high.timeMultiplier / HeatLevel.low.timeMultiplier))
            let savings = duration - max(highTime, 30)

            guard savings > 30 else { return nil } // At least 30s savings worth showing

            return (step: step, originalDuration: duration, optimizedDuration: max(highTime, 30), action: action)
        }
    }

    /// Format seconds to readable time string
    static func formatTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) sec" }
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs == 0 { return "\(minutes) min" }
        return "\(minutes) min \(secs) sec"
    }
}
