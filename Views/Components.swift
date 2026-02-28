import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(Theme.bodyFont(size: 18).weight(.bold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.primary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
            .shadow(color: Theme.primary.opacity(0.3), radius: 10, y: 5)
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.bodyFont(size: 16).weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.primaryLight)
                .foregroundColor(Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
        }
    }
}

struct TabItem: View {
    let image: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.primary : Color.clear, lineWidth: 2)
                        .frame(width: 34, height: 34)

                    Image(systemName: image)
                        .font(.system(size: isSelected ? 16 : 20))
                        .foregroundColor(isSelected ? Theme.primary : Theme.textSecondary)
                }
                .frame(height: 34)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? Theme.primary : Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Banner Carousel

struct BannerCarousel: View {
    @State private var currentIndex: Int = 0
    let autoSlideTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    private let cards: [(title: String, subtitle: String, icon: String, colors: [Color])] = [
        (
            "READY TO COOK?",
            "Guided steps,\nevery time.",
            "stove.fill",
            [Color(hex: "7C3AED"), Color(hex: "A855F7")]
        ),
        (
            "🔥 HEAT OPTIMIZER",
            "Save time with\nsmart heat control.",
            "flame.fill",
            [Color(hex: "F59E0B"), Color(hex: "EF4444")]
        ),
        (
            "🎙️ VOICE ASSISTANT",
            "Hands-free\ncooking guidance.",
            "waveform.circle.fill",
            [Color(hex: "10B981"), Color(hex: "06B6D4")]
        ),
        (
            "📊 TRACK PROGRESS",
            "Rate & improve\nyour dishes.",
            "chart.bar.fill",
            [Color(hex: "3B82F6"), Color(hex: "6366F1")]
        ),
        (
            "⏱️ SMART TIMERS",
            "Auto-start &\ncountdown alerts.",
            "timer.circle.fill",
            [Color(hex: "EC4899"), Color(hex: "F43F5E")]
        )
    ]

    var body: some View {
        VStack(spacing: 10) {
            TabView(selection: $currentIndex) {
                ForEach(0..<cards.count, id: \.self) { index in
                    let card = cards[index]
                    ZStack(alignment: .leading) {
                        LinearGradient(colors: card.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))

                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(card.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.85))
                                Text(card.subtitle)
                                    .font(Theme.titleFont(size: 22))
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.7)
                            }
                            Spacer()
                            Image(systemName: card.icon)
                                .font(.system(size: 70))
                                .foregroundColor(.white.opacity(0.2))
                                .padding(.trailing, -6)
                        }
                        .padding(22)
                    }
                    .tag(index)
                    .shadow(color: card.colors[0].opacity(0.3), radius: 12, y: 8)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 150)
            .onReceive(autoSlideTimer) { _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentIndex = (currentIndex + 1) % cards.count
                }
            }

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<cards.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Theme.primary : Theme.primary.opacity(0.25))
                        .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }
        }
    }
}

#Preview("Primary Button") {
    VStack(spacing: 20) {
        PrimaryButton(title: "Save Recipe", action: {})
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        SecondaryButton(title: "Cancel", action: {})
    }
    .padding()
}
