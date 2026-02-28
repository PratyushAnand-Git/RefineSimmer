import SwiftUI
import SwiftData

struct ActivityView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @State private var viewModel = ActivityViewModel()
    @State private var ratingRecipe: Recipe? = nil
    @State private var ratingSession: CookingSession? = nil
    @State private var pendingRating: Int = 0
    @State private var pendingNotes: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Theme.premiumIcon("clock.arrow.circlepath", color: Theme.primary)
                        .font(.system(size: 28))
                    Text("Activity")
                        .font(Theme.titleFont(size: 28))
                }
                .padding(.horizontal)
                .padding(.top)

                let pendingRatings = pendingRatingItems
                let sessions = viewModel.allSessions(from: recipes)

                if pendingRatings.isEmpty && sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Pending rating notifications
                            if !pendingRatings.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Theme.premiumIcon("bell.badge.fill", color: Theme.accent)
                                        Text("PENDING RATINGS")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.textSecondary)
                                    }

                                    ForEach(pendingRatings, id: \.1.persistentModelID) { recipe, session in
                                        PendingRatingRow(recipe: recipe, session: session) {
                                            ratingRecipe = recipe
                                            ratingSession = session
                                            pendingRating = 0
                                            pendingNotes = ""
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // All sessions
                            if !sessions.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Theme.premiumIcon("list.bullet", color: Theme.primary)
                                        Text("ALL SESSIONS")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.textSecondary)
                                    }

                                    ForEach(sessions, id: \.1.persistentModelID) { recipe, session in
                                        SessionRow(recipe: recipe, session: session) {
                                            ratingRecipe = recipe
                                            ratingSession = session
                                            pendingRating = 0
                                            pendingNotes = ""
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .background(Theme.background)
            .sheet(item: $ratingSession) { session in
                InlineRatingView(
                    recipeName: ratingRecipe?.name ?? "",
                    session: session,
                    rating: $pendingRating,
                    notes: $pendingNotes
                ) {
                    session.rating = pendingRating
                    session.notes = pendingNotes
                    session.suggestions = SuggestionEngine.generateSuggestions(from: pendingNotes)
                    session.ratingFinalized = true  // Rated — never ask again
                    ratingSession = nil
                    ratingRecipe = nil
                }
            }
        }
    }

    private var pendingRatingItems: [(Recipe, CookingSession)] {
        recipes.flatMap { recipe in
            recipe.dismissedUnratedSessions.map { (recipe, $0) }
        }
        .sorted { $0.1.date > $1.1.date }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Theme.premiumIcon("calendar.badge.exclamationmark", color: Theme.primaryLight)
                .font(.system(size: 60))

            Text("No sessions yet")
                .font(Theme.titleFont(size: 18))

            Text("Complete a cooking session to see it here")
                .font(Theme.bodyFont())
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pending Rating Notification Row
struct PendingRatingRow: View {
    let recipe: Recipe
    let session: CookingSession
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "star.bubble.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Add rating to \(recipe.name)")
                        .font(Theme.bodyFont(size: 14).weight(.bold))
                        .foregroundColor(Theme.textMain)

                    Text("Cooked on \(session.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(Theme.bodyFont(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(14)
            .background(Theme.accent.opacity(0.06))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Inline Rating Sheet
struct InlineRatingView: View {
    let recipeName: String
    let session: CookingSession
    @Binding var rating: Int
    @Binding var notes: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                Text("Rate your **\(recipeName)** session")
                    .font(Theme.titleFont(size: 22))

                Text("Cooked on \(session.date.formatted(date: .long, time: .shortened))")
                    .font(Theme.bodyFont(size: 14))
                    .foregroundColor(Theme.textSecondary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("RATING")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textSecondary)

                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundColor(star <= rating ? Theme.accent : Theme.textSecondary.opacity(0.3))
                                .onTapGesture { rating = star }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("NOTES")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textSecondary)

                    TextEditor(text: $notes)
                        .padding(10)
                        .frame(height: 100)
                        .scrollContentBackground(.hidden)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.primaryLight, lineWidth: 1)
                        )
                }

                Spacer()

                PrimaryButton(title: "Submit Rating") {
                    onSubmit()
                }
                .disabled(rating == 0)
                .opacity(rating == 0 ? 0.5 : 1)
            }
            .padding(24)
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Session Row (with Rate button for unrated)
struct SessionRow: View {
    let recipe: Recipe
    let session: CookingSession
    let onRate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(recipe.name)
                    .font(Theme.bodyFont().weight(.bold))
                    .foregroundColor(Theme.textMain)
                Spacer()
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.bodyFont(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }

            HStack {
                if session.rating > 0 {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Theme.premiumIcon("star.fill", color: star <= session.rating ? Theme.accent : Theme.textSecondary.opacity(0.15))
                                .font(.system(size: 14))
                        }
                    }
                } else {
                    Text("Not rated")
                        .font(Theme.bodyFont(size: 13))
                        .foregroundColor(Theme.textSecondary)
                        .italic()
                }

                if !session.notes.isEmpty {
                    Text("•")
                        .foregroundColor(Theme.textSecondary)
                    Text(session.notes)
                        .font(Theme.bodyFont(size: 13))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Rate button for unrated sessions
                if session.rating == 0 {
                    Button(action: onRate) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 14))
                            Text("Rate")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
    }
}

#Preview {
    ActivityView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
