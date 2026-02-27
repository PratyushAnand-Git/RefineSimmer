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

#Preview("Primary Button") {
    VStack(spacing: 20) {
        PrimaryButton(title: "Save Recipe", action: {})
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        SecondaryButton(title: "Cancel", action: {})
    }
    .padding()
}
