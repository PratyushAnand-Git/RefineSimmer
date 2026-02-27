import SwiftUI

// MARK: - Ingredient Emoji Mapper
struct IngredientEmojiMapper {
    private static let map: [(keywords: [String], emoji: String)] = [
        // Vegetables
        (["onion"], "🧅"),
        (["garlic"], "🧄"),
        (["tomato"], "🍅"),
        (["potato"], "🥔"),
        (["carrot"], "🥕"),
        (["broccoli"], "🥦"),
        (["corn"], "🌽"),
        (["pepper", "capsicum", "bell pepper"], "🫑"),
        (["chili", "chilli", "hot pepper"], "🌶️"),
        (["lettuce", "salad", "greens"], "🥬"),
        (["cucumber"], "🥒"),
        (["mushroom"], "🍄"),
        (["eggplant", "aubergine", "brinjal"], "🍆"),
        (["avocado"], "🥑"),
        (["spinach", "kale", "leafy"], "🥬"),
        (["peas", "beans"], "🫛"),
        (["ginger"], "🫚"),

        // Fruits
        (["lemon", "lime", "citrus"], "🍋"),
        (["apple"], "🍎"),
        (["banana"], "🍌"),
        (["orange"], "🍊"),
        (["coconut"], "🥥"),
        (["mango"], "🥭"),
        (["strawberry", "berry"], "🍓"),
        (["grape"], "🍇"),
        (["peach"], "🍑"),
        (["pineapple"], "🍍"),
        (["cherry"], "🍒"),
        (["watermelon", "melon"], "🍉"),

        // Proteins
        (["chicken", "poultry"], "🍗"),
        (["meat", "beef", "steak", "lamb", "pork"], "🥩"),
        (["fish", "salmon", "tuna"], "🐟"),
        (["shrimp", "prawn", "seafood"], "🦐"),
        (["egg"], "🥚"),
        (["bacon"], "🥓"),

        // Dairy
        (["cheese"], "🧀"),
        (["butter"], "🧈"),
        (["milk", "cream"], "🥛"),

        // Grains & Staples
        (["rice"], "🍚"),
        (["bread", "toast"], "🍞"),
        (["pasta", "spaghetti", "noodle"], "🍝"),
        (["flour", "dough"], "🫓"),
        (["pancake", "crepe", "batter"], "🥞"),
        (["tortilla", "wrap"], "🫔"),

        // Seasonings & Liquids
        (["salt"], "🧂"),
        (["honey"], "🍯"),
        (["oil", "olive oil"], "🫒"),
        (["water", "broth", "stock"], "💧"),
        (["sugar"], "🍬"),
        (["chocolate", "cocoa"], "🍫"),
        (["wine", "vinegar"], "🍷"),
        (["sauce", "ketchup"], "🫙"),
        (["soy sauce"], "🫙"),

        // Nuts
        (["almond", "nut", "peanut", "cashew", "walnut"], "🥜"),

        // Baked goods
        (["cake"], "🎂"),
        (["pie"], "🥧"),
        (["cookie", "biscuit"], "🍪"),
        (["cupcake", "muffin"], "🧁"),
    ]

    /// Find the best matching food emoji for a step instruction
    static func findIngredientEmoji(in instruction: String) -> String? {
        let lower = instruction.lowercased()
        for entry in map {
            for keyword in entry.keywords {
                if lower.contains(keyword) {
                    return entry.emoji
                }
            }
        }
        return nil
    }

    /// Find all matching food emojis (up to limit)
    static func findAllIngredientEmojis(in instruction: String, limit: Int = 2) -> [String] {
        let lower = instruction.lowercased()
        var found: [String] = []
        for entry in map {
            for keyword in entry.keywords {
                if lower.contains(keyword) && !found.contains(entry.emoji) {
                    found.append(entry.emoji)
                    if found.count >= limit { return found }
                    break
                }
            }
        }
        return found
    }
}

// MARK: - Cooking Tool Emoji
extension CookingAction {
    var toolEmoji: String {
        switch self {
        case .prep: return "🔪"
        case .mix: return "🥄"
        case .fry, .stirFry: return "🍳"
        case .bake: return "📦"  // oven tray
        case .boil, .simmer: return "🫕"
        case .grill: return "🔥"
        case .steam: return "♨️"
        case .pour: return "🫗"
        case .flip: return "🍳"
        case .coat: return "🧂"
        case .knead: return "🤲"
        case .serve: return "🍽️"
        case .heat: return "🔥"
        case .rest: return "⏳"
        case .cook: return "🥘"
        case .general: return "✨"
        }
    }
}

// MARK: - Cooking Avatar View
struct CookingAvatarView: View {
    let action: CookingAction
    let stepInstruction: String
    let isMale: Bool

    @State private var animate = false

    private var chefEmoji: String {
        isMale ? "👨‍🍳" : "👩‍🍳"
    }

    private var ingredientEmojis: [String] {
        IngredientEmojiMapper.findAllIngredientEmojis(in: stepInstruction, limit: 2)
    }

    private var primaryIngredient: String {
        ingredientEmojis.first ?? action.emoji
    }

    private var secondaryIngredient: String? {
        ingredientEmojis.count > 1 ? ingredientEmojis[1] : nil
    }

    var body: some View {
        ZStack {
            // Background blob
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [Theme.primaryLight.opacity(0.5), Theme.primaryLight.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 140)
                .scaleEffect(animate ? 1.03 : 0.97)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animate)

            // Scene
            actionScene
        }
        .onAppear {
            withAnimation {
                animate = true
            }
        }
    }

    @ViewBuilder
    private var actionScene: some View {
        switch action {
        case .prep:
            choppingScene
        case .mix:
            mixingScene
        case .fry, .stirFry:
            fryingScene
        case .bake:
            bakingScene
        case .boil:
            boilingScene
        case .simmer, .cook:
            simmeringScene
        case .pour:
            pouringScene
        case .flip:
            flippingScene
        case .grill:
            grillingScene
        case .knead:
            kneadingScene
        case .serve:
            servingScene
        case .coat:
            coatingScene
        case .heat:
            heatingScene
        case .steam:
            steamingScene
        case .rest:
            restingScene
        case .general:
            genericScene
        }
    }

    // MARK: - Chopping — knife hits ingredient 🔪🧅
    private var choppingScene: some View {
        HStack(spacing: 4) {
            // Abstract chef hand
            Text("🤚")
                .font(.system(size: 24))
                .rotationEffect(.degrees(-20))
                .offset(y: -14)

            // Knife with clear chopping motion
            Text("🔪")
                .font(.system(size: 38))
                .rotationEffect(.degrees(animate ? -25 : 15))
                .offset(y: animate ? -6 : 6)
                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: animate)

            // Ingredient being chopped
            VStack(spacing: 2) {
                Text(primaryIngredient)
                    .font(.system(size: 40))
                    .scaleEffect(animate ? 0.85 : 1.0)
                    .offset(y: animate ? 3 : -3)
                    .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: animate)

                // Chopped pieces scatter
                if let secondary = secondaryIngredient {
                    Text(secondary)
                        .font(.system(size: 18))
                        .opacity(animate ? 0.4 : 0.9)
                        .offset(x: animate ? 8 : -4, y: 4)
                        .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: animate)
                }
            }
        }
    }

    // MARK: - Mixing — spoon stirs in bowl with ingredient 🥄🥣
    private var mixingScene: some View {
        ZStack {
            // Bowl
            Text("🥣")
                .font(.system(size: 52))

            // Ingredient inside bowl
            Text(primaryIngredient)
                .font(.system(size: 22))
                .offset(x: animate ? -6 : 6, y: -2)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animate)

            // Spoon stirring
            Text("🥄")
                .font(.system(size: 28))
                .rotationEffect(.degrees(animate ? -35 : 35))
                .offset(x: animate ? -8 : 8, y: -18)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animate)
        }
    }

    // MARK: - Frying — pan with ingredient sizzling 🍳
    private var fryingScene: some View {
        ZStack {
            // Pan
            Text("🍳")
                .font(.system(size: 56))
                .rotationEffect(.degrees(animate ? -4 : 4))
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animate)

            // Ingredient in pan
            Text(primaryIngredient)
                .font(.system(size: 26))
                .offset(x: -2, y: -4)
                .scaleEffect(animate ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: animate)

            // Sizzle sparks
            ForEach(0..<3, id: \.self) { i in
                Text("✨")
                    .font(.system(size: 10))
                    .offset(
                        x: CGFloat([-14, 4, 16][i]),
                        y: animate ? -34 : -20
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.5)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
    }

    // MARK: - Baking — ingredient going into oven 🧁♨️
    private var bakingScene: some View {
        VStack(spacing: -4) {
            // Steam rising
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Text("♨️")
                        .font(.system(size: 12))
                        .offset(y: animate ? -10 : 0)
                        .opacity(animate ? 0.1 : 0.7)
                        .animation(
                            .easeOut(duration: 0.9)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.25),
                            value: animate
                        )
                }
            }

            // The baked item
            Text(primaryIngredient)
                .font(.system(size: 50))
                .scaleEffect(animate ? 1.12 : 0.92)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)

            // Oven indicator
            Text("🔥")
                .font(.system(size: 18))
                .opacity(animate ? 1 : 0.4)
                .scaleEffect(animate ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animate)
        }
    }

    // MARK: - Boiling — pot with bubbles and ingredient 🫕💧
    private var boilingScene: some View {
        ZStack {
            Text("🫕")
                .font(.system(size: 52))

            // Ingredient in pot
            Text(primaryIngredient)
                .font(.system(size: 22))
                .offset(y: -6)
                .scaleEffect(animate ? 0.9 : 1.1)
                .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: animate)

            // Bubbles
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: CGFloat([5, 7, 4, 6][i]))
                    .offset(
                        x: CGFloat([-10, 3, 12, -4][i]),
                        y: animate ? -32 : -8
                    )
                    .opacity(animate ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 0.7)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
    }

    // MARK: - Simmering — pot with gentle flame 🍲🔥
    private var simmeringScene: some View {
        ZStack {
            Text("🍲")
                .font(.system(size: 52))

            Text(primaryIngredient)
                .font(.system(size: 20))
                .offset(y: -8)
                .opacity(0.8)

            Text("🔥")
                .font(.system(size: 18))
                .offset(y: 28)
                .scaleEffect(animate ? 1.15 : 0.85)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: animate)
        }
    }

    // MARK: - Pouring — liquid onto ingredient 🫗
    private var pouringScene: some View {
        HStack(spacing: -4) {
            // Container pouring
            Text("🫗")
                .font(.system(size: 36))
                .rotationEffect(.degrees(animate ? -30 : -5))
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animate)

            VStack(spacing: 2) {
                // Drops falling
                ForEach(0..<2, id: \.self) { i in
                    Text("💧")
                        .font(.system(size: 10))
                        .offset(y: animate ? 14 : -4)
                        .opacity(animate ? 0.2 : 1.0)
                        .animation(
                            .easeIn(duration: 0.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.3),
                            value: animate
                        )
                }
            }

            // Target ingredient
            Text(primaryIngredient)
                .font(.system(size: 40))
                .offset(y: 6)
        }
    }

    // MARK: - Flipping — food arcs in the air 🥞
    private var flippingScene: some View {
        ZStack {
            // Pan
            Text("🍳")
                .font(.system(size: 52))

            // Food flipping
            Text(primaryIngredient)
                .font(.system(size: 28))
                .offset(y: animate ? -35 : -5)
                .rotationEffect(.degrees(animate ? 180 : 0))
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: animate)
        }
    }

    // MARK: - Grilling — food on fire 🥩🔥
    private var grillingScene: some View {
        ZStack {
            // Food
            Text(primaryIngredient)
                .font(.system(size: 48))

            // Flames underneath
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Text("🔥")
                        .font(.system(size: 16))
                        .offset(y: 28)
                        .scaleEffect(animate ? 1.3 : 0.7)
                        .animation(
                            .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                            value: animate
                        )
                }
            }

            // Grill marks / sizzle
            if let secondary = secondaryIngredient {
                Text(secondary)
                    .font(.system(size: 18))
                    .offset(x: 24, y: -16)
                    .opacity(0.7)
            }
        }
    }

    // MARK: - Kneading — hands pressing dough 🤲🫓
    private var kneadingScene: some View {
        VStack(spacing: -8) {
            // Hands pressing
            Text("🤲")
                .font(.system(size: 36))
                .offset(y: animate ? 6 : -2)
                .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: animate)

            // Dough squishing
            Text(primaryIngredient)
                .font(.system(size: 40))
                .scaleEffect(x: animate ? 1.25 : 0.85, y: animate ? 0.8 : 1.15)
                .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: animate)
        }
    }

    // MARK: - Serving — plate presentation 🍽️✨
    private var servingScene: some View {
        ZStack {
            Text("🍽️")
                .font(.system(size: 52))

            Text(primaryIngredient)
                .font(.system(size: 28))
                .offset(y: -4)
                .scaleEffect(animate ? 1.08 : 0.95)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animate)

            // Sparkle
            ForEach(0..<3, id: \.self) { i in
                Text("✨")
                    .font(.system(size: 14))
                    .offset(
                        x: CGFloat([-22, 20, 0][i]),
                        y: CGFloat([-20, -18, -30][i])
                    )
                    .opacity(animate ? 1 : 0.2)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
    }

    // MARK: - Coating / Seasoning — sprinkling onto food 🧂
    private var coatingScene: some View {
        ZStack {
            // Food
            Text(primaryIngredient)
                .font(.system(size: 44))

            // Salt shaker
            Text("🧂")
                .font(.system(size: 28))
                .offset(x: 20, y: -28)
                .rotationEffect(.degrees(animate ? -25 : 0))
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animate)

            // Particles falling
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(Theme.accent.opacity(0.6))
                    .frame(width: 3, height: 3)
                    .offset(
                        x: CGFloat([12, 18, 24, 15][i]),
                        y: animate ? 10 : -14
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeIn(duration: 0.4)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.12),
                        value: animate
                    )
            }
        }
    }

    // MARK: - Heating — pan on fire 🔥🍳
    private var heatingScene: some View {
        ZStack {
            Text(primaryIngredient)
                .font(.system(size: 46))

            HStack(spacing: 4) {
                ForEach(0..<2, id: \.self) { i in
                    Text("🔥")
                        .font(.system(size: 20))
                        .offset(y: 26)
                        .scaleEffect(animate ? 1.3 : 0.7)
                        .opacity(animate ? 1.0 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: animate
                        )
                }
            }
        }
    }

    // MARK: - Steaming — clouds rising 🥘☁️
    private var steamingScene: some View {
        ZStack {
            Text(primaryIngredient)
                .font(.system(size: 48))

            ForEach(0..<3, id: \.self) { i in
                Text("☁️")
                    .font(.system(size: 14))
                    .offset(
                        x: CGFloat([-12, 2, 14][i]),
                        y: animate ? -38 : -14
                    )
                    .opacity(animate ? 0 : 0.7)
                    .animation(
                        .easeOut(duration: 1.2)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.35),
                        value: animate
                    )
            }
        }
    }

    // MARK: - Resting — hourglass + food 
    private var restingScene: some View {
        HStack(spacing: 12) {
            Text(primaryIngredient)
                .font(.system(size: 44))

            Text("⏳")
                .font(.system(size: 34))
                .rotationEffect(.degrees(animate ? 180 : 0))
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: animate)
        }
    }

    // MARK: - Generic — food with sparkle
    private var genericScene: some View {
        ZStack {
            Text(primaryIngredient)
                .font(.system(size: 50))
                .scaleEffect(animate ? 1.08 : 0.92)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animate)

            Text("✨")
                .font(.system(size: 20))
                .offset(x: 22, y: -22)
                .opacity(animate ? 1 : 0.3)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animate)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        CookingAvatarView(action: .prep, stepInstruction: "Chop the onions finely", isMale: false)
        CookingAvatarView(action: .fry, stepInstruction: "Fry the chicken until golden", isMale: true)
        CookingAvatarView(action: .bake, stepInstruction: "Bake the cake for 30 minutes", isMale: false)
    }
}
