import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var recipeToEdit: Recipe?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("Refine Simmer")
                            .font(Theme.titleFont(size: 28))
                            .foregroundColor(Theme.textMain)
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Theme.background)
                                .frame(width: 40, height: 40)
                            Theme.premiumIcon("bell.badge.fill", color: Theme.accent)
                        }
                    }
                    .padding(.horizontal)

                    ZStack(alignment: .leading) {
                        LinearGradient(colors: [Theme.primary, Theme.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                            .frame(height: 160)
                            .shadow(color: Theme.primary.opacity(0.3), radius: 15, y: 10)

                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("READY TO COOK?")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))

                                Text("Guided steps,\nevery time.")
                                    .font(Theme.titleFont(size: 24))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Theme.premiumIcon("stove.fill", color: .white.opacity(0.25))
                                .font(.system(size: 100))
                                .padding(.trailing, -10)
                        }
                        .padding(24)
                    }
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
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    RecipeCard(recipe: recipe) {
                                        recipeToEdit = recipe
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.background)
        }
        .sheet(item: $recipeToEdit) { recipe in
            EditRecipeView(recipe: recipe)
        }
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
