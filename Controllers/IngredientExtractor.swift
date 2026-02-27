import Foundation

struct IngredientExtractor {

    // Common cooking ingredients database
    private static let knownIngredients: [String: String] = [
        // Proteins
        "chicken": "Chicken", "beef": "Beef", "pork": "Pork", "lamb": "Lamb",
        "fish": "Fish", "shrimp": "Shrimp", "prawns": "Prawns", "salmon": "Salmon",
        "tuna": "Tuna", "turkey": "Turkey", "tofu": "Tofu", "paneer": "Paneer",
        "egg": "Eggs", "eggs": "Eggs", "bacon": "Bacon", "sausage": "Sausage",

        // Vegetables
        "onion": "Onions", "onions": "Onions", "garlic": "Garlic",
        "tomato": "Tomatoes", "tomatoes": "Tomatoes", "potato": "Potatoes", "potatoes": "Potatoes",
        "carrot": "Carrots", "carrots": "Carrots", "pepper": "Bell Pepper", "peppers": "Bell Peppers",
        "broccoli": "Broccoli", "spinach": "Spinach", "mushroom": "Mushrooms", "mushrooms": "Mushrooms",
        "celery": "Celery", "lettuce": "Lettuce", "cabbage": "Cabbage",
        "corn": "Corn", "peas": "Peas", "beans": "Beans", "lentils": "Lentils",
        "ginger": "Ginger", "cucumber": "Cucumber", "zucchini": "Zucchini",
        "eggplant": "Eggplant", "cauliflower": "Cauliflower", "kale": "Kale",
        "avocado": "Avocado", "asparagus": "Asparagus",

        // Fruits
        "lemon": "Lemon", "lime": "Lime", "orange": "Orange", "apple": "Apple",
        "banana": "Banana", "mango": "Mango", "coconut": "Coconut",

        // Dairy
        "butter": "Butter", "cream": "Cream", "cheese": "Cheese", "milk": "Milk",
        "yogurt": "Yogurt", "curd": "Curd", "ghee": "Ghee",

        // Grains & Staples
        "rice": "Rice", "pasta": "Pasta", "noodles": "Noodles", "flour": "Flour",
        "bread": "Bread", "dough": "Dough", "tortilla": "Tortillas",
        "oats": "Oats", "quinoa": "Quinoa",

        // Oils & Liquids
        "oil": "Oil", "olive oil": "Olive Oil", "vegetable oil": "Vegetable Oil",
        "water": "Water", "broth": "Broth", "stock": "Stock",
        "soy sauce": "Soy Sauce", "vinegar": "Vinegar", "wine": "Wine",

        // Spices & Seasonings
        "salt": "Salt", "pepper powder": "Pepper", "cumin": "Cumin",
        "turmeric": "Turmeric", "paprika": "Paprika", "cinnamon": "Cinnamon",
        "oregano": "Oregano", "basil": "Basil", "thyme": "Thyme",
        "parsley": "Parsley", "cilantro": "Cilantro", "coriander": "Coriander",
        "chili": "Chili", "chilli": "Chili", "cayenne": "Cayenne",
        "rosemary": "Rosemary", "bay leaf": "Bay Leaves", "bay leaves": "Bay Leaves",
        "cloves": "Cloves", "cardamom": "Cardamom", "nutmeg": "Nutmeg",
        "garam masala": "Garam Masala", "curry powder": "Curry Powder",

        // Sweeteners & Baking
        "sugar": "Sugar", "honey": "Honey", "maple syrup": "Maple Syrup",
        "baking powder": "Baking Powder", "baking soda": "Baking Soda",
        "vanilla": "Vanilla Extract", "yeast": "Yeast", "cocoa": "Cocoa Powder",
        "chocolate": "Chocolate", "syrup": "Syrup",

        // Nuts & Seeds
        "almonds": "Almonds", "cashews": "Cashews", "peanuts": "Peanuts",
        "walnuts": "Walnuts", "sesame": "Sesame Seeds",

        // Sauces & Condiments
        "ketchup": "Ketchup", "mustard": "Mustard", "mayonnaise": "Mayonnaise",
        "hot sauce": "Hot Sauce", "tomato sauce": "Tomato Sauce",
        "tomato paste": "Tomato Paste", "coconut milk": "Coconut Milk",
    ]

    // Standard default quantities per ingredient (base for 1 serving/1 pound)
    private static let standardDefaults: [String: String] = [
        // Proteins
        "Chicken": "250 g", "Beef": "250 g", "Pork": "250 g", "Lamb": "250 g",
        "Fish": "200 g", "Shrimp": "150 g", "Prawns": "150 g", "Salmon": "200 g",
        "Tuna": "150 g", "Turkey": "250 g", "Tofu": "200 g", "Paneer": "200 g",
        "Eggs": "2 pieces", "Bacon": "4 slices", "Sausage": "2 pieces",
        // Vegetables
        "Onions": "2 medium", "Garlic": "4 cloves", "Tomatoes": "3 medium",
        "Potatoes": "2 medium", "Carrots": "2 medium", "Bell Pepper": "1 medium",
        "Bell Peppers": "2 medium", "Broccoli": "1 cup", "Spinach": "2 cups",
        "Mushrooms": "1 cup", "Celery": "2 stalks", "Lettuce": "4 leaves",
        "Cabbage": "2 cups", "Corn": "1 cup", "Peas": "1 cup", "Beans": "1 cup",
        "Lentils": "1 cup", "Ginger": "1 tbsp", "Cucumber": "1 medium",
        "Zucchini": "1 medium", "Eggplant": "1 medium", "Cauliflower": "2 cups",
        "Kale": "2 cups", "Avocado": "1 medium", "Asparagus": "6 spears",
        // Fruits
        "Lemon": "1 piece", "Lime": "1 piece", "Orange": "1 piece",
        "Apple": "1 medium", "Banana": "1 medium", "Mango": "1 medium",
        "Coconut": "1 cup",
        // Dairy
        "Butter": "4 tbsp", "Cream": "1 cup", "Cheese": "1 cup",
        "Milk": "1 cup", "Yogurt": "1 cup", "Curd": "1 cup", "Ghee": "2 tbsp",
        // Grains & Staples
        "Rice": "1 cup", "Pasta": "200 g", "Noodles": "200 g", "Flour": "2 cups",
        "Bread": "4 slices", "Dough": "2 cups", "Tortillas": "4 pieces",
        "Oats": "1 cup", "Quinoa": "1 cup",
        // Oils & Liquids
        "Oil": "3 tbsp", "Olive Oil": "3 tbsp", "Vegetable Oil": "3 tbsp",
        "Water": "2 cups", "Broth": "2 cups", "Stock": "2 cups",
        "Soy Sauce": "2 tbsp", "Vinegar": "1 tbsp", "Wine": "0.5 cup",
        // Spices & Seasonings
        "Salt": "1 tsp", "Pepper": "0.5 tsp", "Cumin": "1 tsp",
        "Turmeric": "0.5 tsp", "Paprika": "1 tsp", "Cinnamon": "0.5 tsp",
        "Oregano": "1 tsp", "Basil": "1 tsp", "Thyme": "0.5 tsp",
        "Parsley": "2 tbsp", "Cilantro": "2 tbsp", "Coriander": "1 tsp",
        "Chili": "1 tsp", "Cayenne": "0.5 tsp",
        "Rosemary": "1 tsp", "Bay Leaves": "2 pieces", "Cloves": "4 pieces",
        "Cardamom": "3 pieces", "Nutmeg": "0.25 tsp",
        "Garam Masala": "1 tsp", "Curry Powder": "1 tbsp",
        // Sweeteners & Baking
        "Sugar": "6 tbsp", "Honey": "2 tbsp", "Maple Syrup": "2 tbsp",
        "Baking Powder": "1 tsp", "Baking Soda": "0.5 tsp",
        "Vanilla Extract": "1 tsp", "Yeast": "1 tsp", "Cocoa Powder": "3 tbsp",
        "Chocolate": "100 g", "Syrup": "2 tbsp",
        // Nuts & Seeds
        "Almonds": "0.25 cup", "Cashews": "0.25 cup", "Peanuts": "0.25 cup",
        "Walnuts": "0.25 cup", "Sesame Seeds": "1 tbsp",
        // Sauces & Condiments
        "Ketchup": "2 tbsp", "Mustard": "1 tbsp", "Mayonnaise": "2 tbsp",
        "Hot Sauce": "1 tsp", "Tomato Sauce": "1 cup",
        "Tomato Paste": "2 tbsp", "Coconut Milk": "1 cup",
    ]

    /// Extract ingredients from an array of step instructions
    static func extractIngredients(from steps: [String]) -> [Ingredient] {
        var foundIngredients: [String: String] = [:] // name -> quantity
        let allText = steps.joined(separator: " ").lowercased()

        // Multi-word ingredients first (longer matches take priority)
        let sortedKeys = knownIngredients.keys.sorted { $0.count > $1.count }

        for key in sortedKeys {
            guard let displayName = knownIngredients[key] else { continue }
            // Skip if we already found this ingredient under its display name
            if foundIngredients.keys.contains(displayName) { continue }

            if allText.contains(key) {
                let quantity = extractQuantity(for: key, in: allText)
                if quantity.isEmpty {
                    // Use standard default
                    foundIngredients[displayName] = standardDefaults[displayName] ?? "As needed"
                } else {
                    foundIngredients[displayName] = quantity
                }
            }
        }

        return foundIngredients.map { name, quantity in
            Ingredient(name: name, quantity: quantity)
        }
        .sorted { $0.name < $1.name }
    }

    /// Try to find a quantity near the ingredient mention
    private static func extractQuantity(for ingredient: String, in text: String) -> String {
        // Look for quantity pattern right before the ingredient word
        let pattern = #"(\d+[\./]?\d*\s*(?:cups?|tbsp|tsp|tablespoons?|teaspoons?|oz|ounces?|lbs?|pounds?|kg|g|grams?|ml|liters?|litres?|pieces?|cloves?|slices?|bunch|pinch|dash|large|medium|small|whole)?)\s*(?:of\s+)?"# + NSRegularExpression.escapedPattern(for: ingredient)

        if let range = text.range(of: pattern, options: .regularExpression) {
            let match = String(text[range])
            // Extract just the quantity part
            let ingredientRange = match.range(of: ingredient, options: .caseInsensitive)
            if let ir = ingredientRange {
                return String(match[match.startIndex..<ir.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return ""
    }

    /// Detect cooking action type from a step instruction for smart timer defaults
    static func detectCookingAction(from instruction: String) -> CookingAction {
        let lower = instruction.lowercased()

        // Multi-word matches first (order matters)
        if lower.contains("stir fry") || lower.contains("stir-fry") { return .stirFry }
        if lower.contains("deep fry") || lower.contains("deep-fry") { return .fry }

        // Baking
        if lower.contains("bake") || lower.contains("roast") || lower.contains("oven") { return .bake }

        // Boiling / Simmering
        if lower.contains("boil") || lower.contains("blanch") { return .boil }
        if lower.contains("simmer") || lower.contains("reduce") { return .simmer }

        // Frying
        if lower.contains("fry") || lower.contains("sauté") || lower.contains("saute") || lower.contains("sear") || lower.contains("pan ") { return .fry }

        // Flipping
        if lower.contains("flip") || lower.contains("turn over") || lower.contains("turn the") { return .flip }

        // Grilling
        if lower.contains("grill") || lower.contains("broil") || lower.contains("char") { return .grill }

        // Steaming
        if lower.contains("steam") { return .steam }

        // Kneading / Dough
        if lower.contains("knead") || lower.contains("roll out") || lower.contains("flatten") || lower.contains("shape") { return .knead }

        // Chopping / Prep
        if lower.contains("chop") || lower.contains("dice") || lower.contains("slice") || lower.contains("mince")
            || lower.contains("cut") || lower.contains("peel") || lower.contains("trim") || lower.contains("grate")
            || lower.contains("crush") || lower.contains("julienne") { return .prep }

        // Mixing / Stirring
        if lower.contains("mix") || lower.contains("stir") || lower.contains("whisk") || lower.contains("blend")
            || lower.contains("fold") || lower.contains("combine") || lower.contains("beat") || lower.contains("cream")
            || lower.contains("toss") { return .mix }

        // Pouring / Adding
        if lower.contains("pour") || lower.contains("drizzle") || lower.contains("add") || lower.contains("sprinkle") { return .pour }

        // Seasoning / Coating
        if lower.contains("season") || lower.contains("coat") || lower.contains("marinate") || lower.contains("rub")
            || lower.contains("brush") || lower.contains("glaze") { return .coat }

        // Resting / Soaking
        if lower.contains("rest") || lower.contains("soak") || lower.contains("cool") || lower.contains("chill")
            || lower.contains("set aside") || lower.contains("let it") || lower.contains("refrigerat") { return .rest }

        // Heating / Preheating
        if lower.contains("preheat") || lower.contains("heat") || lower.contains("warm") { return .heat }

        // Serving / Plating
        if lower.contains("serve") || lower.contains("plate") || lower.contains("garnish") || lower.contains("top with")
            || lower.contains("arrange") || lower.contains("transfer") { return .serve }

        // Cooking (generic catch-all that still shows an icon)
        if lower.contains("cook") { return .cook }

        return .general
    }

    /// Suggest a default duration based on cooking action
    static func suggestDuration(for action: CookingAction) -> Int? {
        switch action {
        case .boil: return 600       // 10 min
        case .simmer: return 1200    // 20 min
        case .fry: return 300        // 5 min
        case .stirFry: return 180    // 3 min
        case .bake: return 1800      // 30 min
        case .grill: return 600      // 10 min
        case .steam: return 600      // 10 min
        case .rest: return 900       // 15 min
        case .heat: return 120       // 2 min
        case .prep: return nil
        case .mix: return nil
        case .pour: return nil
        case .flip: return 60        // 1 min
        case .coat: return nil
        case .knead: return 300      // 5 min
        case .serve: return nil
        case .cook: return 300       // 5 min
        case .general: return nil
        }
    }
}

enum CookingAction: String, CaseIterable {
    case boil, simmer, fry, stirFry, bake, grill, steam
    case rest, heat, prep, mix, pour, flip, coat, knead, serve, cook, general

    var label: String {
        switch self {
        case .boil: return "Boiling"
        case .simmer: return "Simmering"
        case .fry: return "Frying"
        case .stirFry: return "Stir Frying"
        case .bake: return "Baking"
        case .grill: return "Grilling"
        case .steam: return "Steaming"
        case .rest: return "Resting"
        case .heat: return "Heating"
        case .prep: return "Prepping"
        case .mix: return "Mixing"
        case .pour: return "Adding"
        case .flip: return "Flipping"
        case .coat: return "Seasoning"
        case .knead: return "Kneading"
        case .serve: return "Serving"
        case .cook: return "Cooking"
        case .general: return "Step"
        }
    }

    var icon: String {
        switch self {
        case .boil: return "flame.fill"
        case .simmer: return "flame"
        case .fry, .stirFry: return "frying.pan.fill"
        case .bake: return "oven.fill"
        case .grill: return "flame.fill"
        case .steam: return "cloud.fill"
        case .rest: return "clock.fill"
        case .heat: return "thermometer.sun.fill"
        case .prep: return "knife.fill"
        case .mix: return "arrow.triangle.2.circlepath"
        case .pour: return "drop.fill"
        case .flip: return "arrow.up.arrow.down"
        case .coat: return "wand.and.stars"
        case .knead: return "hand.raised.fill"
        case .serve: return "fork.knife"
        case .cook: return "cooktop.fill"
        case .general: return "play.circle.fill"
        }
    }

    /// Emoji for the animated avatar scene
    var emoji: String {
        switch self {
        case .boil: return "♨️"
        case .simmer: return "🫕"
        case .fry, .stirFry: return "🍳"
        case .bake: return "🧁"
        case .grill: return "🥩"
        case .steam: return "💨"
        case .rest: return "⏳"
        case .heat: return "🔥"
        case .prep: return "🔪"
        case .mix: return "🥄"
        case .pour: return "🫗"
        case .flip: return "🥞"
        case .coat: return "🧂"
        case .knead: return "🫓"
        case .serve: return "🍽️"
        case .cook: return "🍲"
        case .general: return "👀"
        }
    }
}
