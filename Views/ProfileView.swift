import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @AppStorage("RS_UserName") var userName: String = "Home Chef"
    @AppStorage("RS_SelectedAvatar") var selectedAvatarIndex: Int = 0
    @State private var viewModel = ProfileViewModel()
    @FocusState private var isEditingFocused: Bool
    @Environment(AppNavigation.self) private var appNav: AppNavigation?

    // All skin-tone and gender variants
    private let avatarOptions: [(emoji: String, label: String)] = [
        // Female chefs
        ("👩‍🍳", "Woman"),
        ("👩🏻‍🍳", "Woman Light"),
        ("👩🏼‍🍳", "Woman Med-Light"),
        ("👩🏽‍🍳", "Woman Medium"),
        ("👩🏾‍🍳", "Woman Med-Dark"),
        ("👩🏿‍🍳", "Woman Dark"),
        // Male chefs
        ("👨‍🍳", "Man"),
        ("👨🏻‍🍳", "Man Light"),
        ("👨🏼‍🍳", "Man Med-Light"),
        ("👨🏽‍🍳", "Man Medium"),
        ("👨🏾‍🍳", "Man Med-Dark"),
        ("👨🏿‍🍳", "Man Dark"),
        // Gender-neutral chefs
        ("🧑‍🍳", "Person"),
        ("🧑🏻‍🍳", "Person Light"),
        ("🧑🏼‍🍳", "Person Med-Light"),
        ("🧑🏽‍🍳", "Person Medium"),
        ("🧑🏾‍🍳", "Person Med-Dark"),
        ("🧑🏿‍🍳", "Person Dark"),
    ]

    private var currentAvatar: String {
        let index = min(selectedAvatarIndex, avatarOptions.count - 1)
        return avatarOptions[max(0, index)].emoji
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Purple header section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Profile")
                                .font(Theme.titleFont(size: 28))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            // Avatar circle
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                Text(currentAvatar)
                                    .font(.system(size: 52))
                                    .minimumScaleFactor(0.5)
                            }

                            // Editable name
                            HStack(spacing: 8) {
                                if viewModel.isEditingName {
                                    TextField("Enter your name", text: $userName)
                                        .textFieldStyle(.plain)
                                        .font(Theme.titleFont(size: 24))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .onSubmit {
                                            viewModel.isEditingName = false
                                        }
                                        .frame(maxWidth: 200)
                                        .focused($isEditingFocused)
                                } else {
                                    Text(userName)
                                        .font(Theme.titleFont(size: 24))
                                        .foregroundColor(.white)
                                }

                                Button(action: {
                                    viewModel.toggleEditing()
                                    if viewModel.isEditingName {
                                        isEditingFocused = true
                                    }
                                }) {
                                    Theme.premiumIcon(
                                        viewModel.isEditingName ? "checkmark.circle.fill" : "pencil.circle.fill",
                                        color: .white
                                    )
                                    .font(.system(size: 20))
                                }
                            }

                            // Slidable avatar picker
                            VStack(spacing: 6) {
                                Text("CHOOSE YOUR AVATAR")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(Array(avatarOptions.enumerated()), id: \.offset) { index, option in
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedAvatarIndex = index
                                                }
                                            }) {
                                                Text(option.emoji)
                                                    .font(.system(size: selectedAvatarIndex == index ? 34 : 24))
                                                    .padding(6)
                                                    .background(
                                                        selectedAvatarIndex == index
                                                            ? Color.white.opacity(0.35)
                                                            : Color.white.opacity(0.1)
                                                    )
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(
                                                                selectedAvatarIndex == index ? Color.white : Color.clear,
                                                                lineWidth: 2
                                                            )
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }

                            Text("Cooking with Refine Simmer")
                                .font(Theme.bodyFont(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.bottom, 8)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 50)
                    .frame(maxWidth: .infinity)
                    .background(Theme.primary)

                    // Stats card — ABOVE the background, not overlapping text
                    HStack(spacing: 0) {
                        StatItem(value: "\(viewModel.recipeCount(recipes))", label: "Recipes")
                        Divider().frame(height: 40)
                        StatItem(value: "\(viewModel.totalSessions(recipes))", label: "Sessions")
                        Divider().frame(height: 40)
                        StatItem(value: viewModel.avgRating(recipes), label: "Avg Rating")
                    }
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
                    .padding(.horizontal, 24)
                    .offset(y: -24)
                    .zIndex(1)

                    // Recipes list
                    VStack(alignment: .leading, spacing: 16) {
                        Text("MY RECIPES")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textSecondary)

                        if recipes.isEmpty {
                            Text("No recipes saved yet")
                                .font(Theme.bodyFont())
                                .foregroundColor(Theme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        } else {
                            ForEach(recipes) { recipe in
                                Button(action: {
                                    // Navigate to Home tab and highlight this recipe
                                    appNav?.navigateToRecipe(named: recipe.name)
                                }) {
                                    HStack {
                                        Text(recipe.name)
                                            .font(Theme.bodyFont().weight(.bold))
                                            .foregroundColor(Theme.textMain)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, -8) // Compensate for offset
                }
            }
            .background(Theme.background)
            .ignoresSafeArea(edges: .top)
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.titleFont(size: 24))
                .foregroundColor(Theme.primary)
            Text(label)
                .font(Theme.bodyFont(size: 12))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
