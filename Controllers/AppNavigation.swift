import SwiftUI
import Observation

/// Shared navigation state that allows cross-tab communication
@Observable
class AppNavigation {
    var selectedTab: Int = 0
    var highlightedRecipeName: String? = nil
    var shouldDismissCookingFlow: Bool = false

    /// Navigate from Profile → Home and highlight a recipe
    func navigateToRecipe(named name: String) {
        highlightedRecipeName = name
        selectedTab = 0  // Switch to Home tab

        // Clear highlight after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.highlightedRecipeName = nil
            }
        }
    }

    /// Called after cooking session to return to Home
    func returnToHome() {
        shouldDismissCookingFlow = true
        selectedTab = 0
        // Reset flag after giving time for dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.shouldDismissCookingFlow = false
        }
    }
}
