import SwiftUI
import SwiftData

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Recipe.self,
            Ingredient.self,
            Step.self,
            CookingSession.self
        ])
    }
}
