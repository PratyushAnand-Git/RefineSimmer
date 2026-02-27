import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @AppStorage("RS_UserName") var userName: String = "Home Chef"
    @AppStorage("RS_UserGender") var userGender: String = "female"
    @State private var viewModel = ProfileViewModel()
    @FocusState private var isEditingFocused: Bool

    private var avatarEmoji: String {
        userGender == "male" ? "👨‍🍳" : "👩‍🍳"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 20) {
                    HStack {
                        Text("Profile")
                            .font(Theme.titleFont(size: 28))
                            .foregroundColor(.white)
                        Spacer()
                        Theme.premiumIcon("bell.badge.fill", color: Theme.accent)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 100, height: 100)
                            Text(avatarEmoji)
                                .font(.system(size: 56))
                        }

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

                        // Gender picker
                        HStack(spacing: 0) {
                            ForEach(["female", "male", "other"], id: \.self) { gender in
                                Button(action: { withAnimation { userGender = gender } }) {
                                    Text(gender == "male" ? "👨‍🍳" : gender == "female" ? "👩‍🍳" : "🧑‍🍳")
                                        .font(.system(size: 22))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(userGender == gender ? Color.white.opacity(0.3) : Color.clear)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())

                        Text("Cooking with Refine Simmer")
                            .font(Theme.bodyFont(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 40)
                .frame(maxWidth: .infinity)
                .background(Theme.primary)

                HStack(spacing: 0) {
                    StatItem(value: "\(viewModel.recipeCount(recipes))", label: "Recipes")
                    Divider().frame(height: 40)
                    StatItem(value: "\(viewModel.totalSessions(recipes))", label: "Sessions")
                    Divider().frame(height: 40)
                    StatItem(value: viewModel.avgRating(recipes), label: "Avg Rating")
                }
                .padding(.vertical, 24)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 24)
                .offset(y: -30)

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
                            HStack {
                                Text(recipe.name)
                                    .font(Theme.bodyFont().weight(.bold))
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
                .padding(.horizontal, 24)

                Spacer()
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
