import SwiftUI
import SwiftData

struct PostCookingReviewView: View {
    let recipe: Recipe
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var isFinished = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if isFinished {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Theme.primary)

                        Text("Session Complete!")
                            .font(Theme.titleFont(size: 28))

                        Text("Your feedback has been saved. We'll show you improvement tips next time you cook this recipe.")
                            .font(Theme.bodyFont())
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        PrimaryButton(title: "Back to Home") {
                            dismiss()
                        }
                        .padding(.top, 20)
                    }
                    .transition(.scale)
                } else {
                    VStack(alignment: .leading, spacing: 32) {
                        // Close button
                        HStack {
                            Spacer()
                            Button(action: {
                                // Save skipped session with rating 0
                                let session = CookingSession(rating: 0)
                                recipe.sessions.append(session)
                                try? modelContext.save()
                                dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        Text("How was your cooking session?")
                            .font(Theme.titleFont(size: 28))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("RATING")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textSecondary)

                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 36))
                                        .foregroundColor(star <= rating ? Theme.accent : Theme.textSecondary.opacity(0.3))
                                        .onTapGesture {
                                            rating = star
                                        }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("NOTES & OBSERVATIONS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textSecondary)

                            TextEditor(text: $notes)
                                .padding(10)
                                .frame(height: 150)
                                .scrollContentBackground(.hidden)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.primaryLight, lineWidth: 1)
                                )
                                .overlay(
                                    Group {
                                        if notes.isEmpty {
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

                        PrimaryButton(title: "Save & Finish") {
                            let suggestions = SuggestionEngine.generateSuggestions(from: notes)
                            let session = CookingSession(rating: rating, notes: notes, suggestions: suggestions)
                            recipe.sessions.append(session)
                            try? modelContext.save()
                            withAnimation {
                                isFinished = true
                            }
                        }
                        .disabled(rating == 0)
                        .opacity(rating == 0 ? 0.5 : 1)
                    }
                }
            }
            .padding(24)
            .background(Theme.background)
        }
    }
}

#Preview {
    PostCookingReviewView(recipe: Recipe.sample)
        .modelContainer(for: Recipe.self, inMemory: true)
}
