import SwiftUI

struct MainTabView: View {
    @State private var appNav = AppNavigation()
    @State private var showingAddRecipe = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $appNav.selectedTab) {
                HomeView()
                    .tag(0)

                ActivityView()
                    .tag(1)

                Color.clear
                    .tag(2)

                ProfileView()
                    .tag(3)
            }

            HStack(spacing: 0) {
                TabItem(image: "house.circle.fill", label: "Home", isSelected: appNav.selectedTab == 0) {
                    appNav.selectedTab = 0
                }

                TabItem(image: "chart.bar.doc.horizontal.fill", label: "Activity", isSelected: appNav.selectedTab == 1) {
                    appNav.selectedTab = 1
                }

                Button(action: { showingAddRecipe = true }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color.clear, lineWidth: 2)
                                .frame(width: 34, height: 34)

                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(height: 34)

                        Text("Add")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                TabItem(image: "person.crop.circle.fill", label: "Profile", isSelected: appNav.selectedTab == 3) {
                    appNav.selectedTab = 3
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 34)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .sheet(isPresented: $showingAddRecipe) {
            AddRecipeView()
        }
        .environment(appNav)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
