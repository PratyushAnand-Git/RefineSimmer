import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigation.self) private var appNav: AppNavigation?
    @State private var viewModel = HomeViewModel()
    @State private var recipeToEdit: Recipe?
    @State private var showingNotifications = false
    @State private var expandedNotificationId: String? = nil
    @State private var ratingRecipe: Recipe? = nil
    @State private var ratingSession: CookingSession? = nil

    /// All pending bell notifications across all recipes
    private var pendingNotifications: [(recipe: Recipe, session: CookingSession)] {
        recipes.flatMap { recipe in
            recipe.bellNotificationSessions.map { (recipe: recipe, session: $0) }
        }
        .sorted { $0.session.date > $1.session.date }
    }

    private var hasNotifications: Bool {
        !pendingNotifications.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Text("Refine Simmer")
                            .font(Theme.titleFont(size: 28))
                            .foregroundColor(Theme.textMain)
                        Spacer()

                        // Notification Bell
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingNotifications.toggle()
                                expandedNotificationId = nil
                            }
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Circle()
                                    .fill(Theme.background)
                                    .frame(width: 40, height: 40)
                                Image(systemName: hasNotifications ? "bell.fill" : "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(hasNotifications ? Theme.accent : Theme.textSecondary.opacity(0.4))

                                // Red dot
                                if hasNotifications {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Notification Panel
                    if showingNotifications {
                        notificationPanel
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Auto-sliding banner carousel
                    BannerCarousel()
                        .padding(.horizontal)

                    HStack {
                        Theme.premiumIcon("fork.knife.circle.fill", color: Theme.primary)
                            .font(.system(size: 24))
                        Text("My Recipes")
                            .font(Theme.titleFont(size: 20))
                    }
                    .padding(.horizontal)

                    if recipes.isEmpty {
                        EmptyRecipesView()
                    } else {
                        VStack(spacing: 16) {
                            ForEach(recipes) { recipe in
                                let isHighlighted = appNav?.highlightedRecipeName == recipe.name
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    RecipeCard(recipe: recipe) {
                                        recipeToEdit = recipe
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Theme.primary, lineWidth: isHighlighted ? 3 : 0)
                                        .shadow(color: isHighlighted ? Theme.primary.opacity(0.4) : .clear, radius: 8)
                                )
                                .scaleEffect(isHighlighted ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 0.4).repeatCount(3, autoreverses: true), value: isHighlighted)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .animation(.easeInOut(duration: 0.25), value: showingNotifications)
        }
        .sheet(item: $recipeToEdit) { recipe in
            EditRecipeView(recipe: recipe)
        }
        .sheet(isPresented: Binding(
            get: { ratingRecipe != nil },
            set: { if !$0 { ratingRecipe = nil; ratingSession = nil } }
        )) {
            if let recipe = ratingRecipe {
                NotificationRatingView(recipe: recipe, session: ratingSession)
            }
        }
    }

    // MARK: - Notification Panel
    private var notificationPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(Theme.accent)
                    .font(.system(size: 14))
                Text("PENDING RATINGS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(pendingNotifications.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accent)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            if pendingNotifications.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.success)
                        Text("All caught up!")
                            .font(Theme.bodyFont(size: 14))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(pendingNotifications, id: \.session.persistentModelID) { item in
                    notificationRow(recipe: item.recipe, session: item.session)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Notification Row
    private func notificationRow(recipe: Recipe, session: CookingSession) -> some View {
        let isExpanded = expandedNotificationId == session.persistentModelID.hashValue.description

        return VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Dismiss small button (leftmost)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        session.dismissedFromNotification = true
                        try? modelContext.save()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textSecondary.opacity(0.4))
                }

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(recipe.name)
                        .font(Theme.bodyFont(size: 15).weight(.semibold))
                        .foregroundColor(Theme.textMain)
                    Text("Rate your cooking session")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                // Date badge
                Text(timeAgo(session.date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.background)
                    .clipShape(Capsule())

                // Expand arrow
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedNotificationId = isExpanded ? nil : session.persistentModelID.hashValue.description
                }
            }

            // Expanded actions
            if isExpanded {
                HStack(spacing: 12) {
                    Button(action: {
                        ratingRecipe = recipe
                        ratingSession = session
                        withAnimation {
                            showingNotifications = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13))
                            Text("Rate Now")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.primary)
                        .clipShape(Capsule())
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            session.dismissedFromNotification = true
                            try? modelContext.save()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 13))
                            Text("Dismiss")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.background)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .padding(.leading, 46)
        }
    }

    // MARK: - Time Ago
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        let days = Int(interval / 86400)
        if days == 1 { return "yesterday" }
        return "\(days)d ago"
    }
}

// MARK: - Notification Rating View
struct NotificationRatingView: View {
    let recipe: Recipe
    let session: CookingSession?
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var rating: Int = 0
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                Text("How was your last time cooking **\(recipe.name)**?")
                    .font(Theme.titleFont(size: 24))

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
                    Text("NOTES & OBSERVATIONS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textSecondary)

                    TextEditor(text: $notes)
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

                PrimaryButton(title: "Submit Rating") {
                    if let session = session {
                        session.rating = rating
                        session.notes = notes
                        session.suggestions = SuggestionEngine.generateSuggestions(from: notes)
                        session.dismissedFromNotification = true
                        session.ratingFinalized = true  // Never ask again
                        try? modelContext.save()
                    }
                    dismiss()
                }
                .disabled(rating == 0)
                .opacity(rating == 0 ? 0.5 : 1)
            }
            .padding(24)
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(recipe.name)
                    .font(Theme.titleFont(size: 18))
                    .foregroundColor(Theme.textMain)
                Spacer()

                Button(action: onEdit) {
                    Theme.premiumIcon("pencil.circle.fill", color: Theme.primary)
                        .font(.system(size: 22))
                }

                HStack(spacing: 6) {
                    Theme.premiumIcon("flame.fill", color: Theme.accent)
                        .font(.system(size: 14))
                    Text("\(recipe.attemptsCount) attempts")
                        .font(Theme.bodyFont(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.background)
                .clipShape(Capsule())
            }

            if !recipe.latestSuggestions.isEmpty {
                HStack(spacing: 8) {
                    Theme.premiumIcon("lightbulb.2.fill", color: Theme.accent)
                        .font(.system(size: 16))
                    Text("Found \(recipe.latestSuggestions.count) improvements")
                        .font(Theme.bodyFont(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct EmptyRecipesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Theme.premiumIcon("takeoutbag.and.cup.and.straw.fill", color: Theme.primaryLight)
                .font(.system(size: 80))

            Text("No recipes yet")
                .font(Theme.titleFont(size: 20))

            Text("Add your first recipe to get started on your cooking journey.")
                .font(Theme.bodyFont())
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
