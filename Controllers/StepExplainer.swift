import Foundation

/// ML-powered step explanation engine
/// Generates how-to summaries, pro tips, and ingredient details for each cooking step
struct StepExplainer {

    struct Explanation {
        let howTo: String
        let proTips: [String]
        let ingredientsNeeded: [String]
    }

    /// Generate an explanation for a step instruction
    static func explain(_ instruction: String) -> Explanation {
        let lower = instruction.lowercased()

        // Extract ingredients mentioned
        let ingredients = extractIngredientsFromStep(lower)

        // Detect primary action
        let action = IngredientExtractor.detectCookingAction(from: instruction)

        // Generate contextual how-to
        let howTo = generateHowTo(instruction: lower, action: action, ingredients: ingredients)

        // Generate pro tips
        let tips = generateTips(instruction: lower, action: action, ingredients: ingredients)

        return Explanation(howTo: howTo, proTips: tips, ingredientsNeeded: ingredients)
    }

    // MARK: - How-To Generation

    private static func generateHowTo(instruction: String, action: CookingAction, ingredients: [String]) -> String {
        let lower = instruction.lowercased()

        // Action-specific detailed instructions
        switch action {
        case .prep:
            if lower.contains("chop") {
                let item = ingredients.first ?? "ingredient"
                return "Place \(item) on a clean cutting board. Using a sharp chef's knife, cut into roughly uniform pieces (about ½ inch). Keep your fingers curled under and use a rocking motion with the knife."
            }
            if lower.contains("dice") {
                let item = ingredients.first ?? "ingredient"
                return "Cut \(item) into thin slices first, then cut across into strips, and finally crosswise into small, even cubes (about ¼ inch)."
            }
            if lower.contains("slice") {
                let item = ingredients.first ?? "ingredient"
                return "Hold \(item) firmly and cut into even, thin slices using a sharp knife. Try to maintain consistent thickness for even cooking."
            }
            if lower.contains("mince") {
                let item = ingredients.first ?? "ingredient"
                return "First roughly chop \(item), then rock the knife back and forth over the pieces until they're very fine. You can also use a garlic press for garlic."
            }
            if lower.contains("peel") {
                let item = ingredients.first ?? "ingredient"
                return "Use a vegetable peeler or paring knife to remove the outer skin of \(item). Work from top to bottom in long strokes."
            }
            if lower.contains("grate") {
                let item = ingredients.first ?? "ingredient"
                return "Hold \(item) against the grater at a 45° angle. Use long, steady strokes in one direction. Watch your fingers as you get closer to the end."
            }
            return "Prepare \(ingredients.first ?? "the ingredient") as described. Use a sharp knife on a stable cutting board for best results."

        case .mix:
            if lower.contains("whisk") {
                return "Use a whisk or fork in a brisk circular motion. Lift the whisk slightly with each stroke to incorporate air. Continue until the mixture is smooth and uniform."
            }
            if lower.contains("fold") {
                return "Use a spatula to gently cut through the center of the mixture, sweep along the bottom, and fold over the top. Rotate the bowl 90° and repeat. Be gentle to preserve air bubbles."
            }
            if lower.contains("beat") {
                return "Use an electric mixer or whisk vigorously by hand. Beat until the mixture is smooth and slightly increased in volume."
            }
            let items = ingredients.joined(separator: ", ")
            if lower.contains("dry") || (lower.contains("flour") && lower.contains("sugar")) {
                return "Combine \(items.isEmpty ? "dry ingredients" : items) in a large bowl. Whisk together thoroughly to distribute all ingredients evenly — this prevents lumps and ensures consistent flavor."
            }
            return "Combine \(items.isEmpty ? "all ingredients" : items) in a bowl. Stir gently until just combined — overmixing can make the result tough."

        case .pour:
            if lower.contains("drizzle") {
                return "Pour in a thin, steady stream from a height of about 6 inches. Move your hand slowly over the surface for even distribution."
            }
            let items = ingredients.joined(separator: ", ")
            if lower.contains("well") || lower.contains("center") {
                return "Make a small well in the center of the dry mix. Pour \(items.isEmpty ? "the liquid ingredients" : items) into the well. This prevents splashing and ensures even incorporation."
            }
            return "Add \(items.isEmpty ? "ingredients" : items) to the mixture. Pour slowly and steadily to control the amount."

        case .fry, .stirFry:
            let items = ingredients.joined(separator: ", ")
            if lower.contains("golden") {
                return "Heat oil in a pan over medium-high heat until it shimmers. Add \(items.isEmpty ? "the ingredients" : items) in a single layer. Don't stir for the first minute — let them develop a golden crust, then flip."
            }
            if lower.contains("sauté") || lower.contains("saute") {
                return "Heat oil or butter in a pan over medium heat. Add \(items.isEmpty ? "the ingredients" : items) and cook, stirring occasionally. The pan should sizzle but not smoke."
            }
            return "Cook \(items.isEmpty ? "the ingredients" : items) in hot oil. Keep the pan at medium-high heat and stir as needed to prevent burning."

        case .boil:
            return "Bring water or liquid to a rolling boil (large, vigorous bubbles). Then add your ingredients. A full boil means bubbles break the surface rapidly."

        case .simmer:
            if lower.contains("reduce") {
                return "Lower the heat until you see gentle, small bubbles occasionally breaking the surface. Cover partially and let it cook slowly — this concentrates flavors and thickens the sauce."
            }
            return "Reduce heat to low-medium. You should see gentle bubbles rising slowly — not a vigorous boil. Stir occasionally to prevent sticking on the bottom."

        case .heat:
            if lower.contains("oil") {
                return "Pour oil into the pan and heat over medium-low flame. The oil is ready when it flows easily across the pan and a small piece of ingredient sizzles when dropped in."
            }
            if lower.contains("preheat") || lower.contains("oven") {
                return "Set your oven to the specified temperature and wait until it reaches that temperature (usually 10-15 minutes). Most ovens beep or show an indicator."
            }
            return "Place pan on the stove over the specified heat level. Allow it to warm up for 1-2 minutes before adding ingredients."

        case .bake:
            return "Place in the preheated oven on the middle rack. Set a timer and avoid opening the oven door frequently — this causes temperature drops that affect the result."

        case .grill:
            return "Ensure the grill is preheated and clean. Oil the grates lightly. Place food on the grill and resist the urge to move it — let it develop grill marks before flipping."

        case .steam:
            return "Add about an inch of water to the pot. Place ingredients in a steamer basket above the water (don't let them touch). Cover tightly and maintain a gentle boil."

        case .flip:
            return "Use a thin spatula, slide it fully under the food. In one confident motion, flip it over. Hesitation causes breaking — commit to the flip!"

        case .coat:
            if lower.contains("marinate") {
                return "Place the ingredient in a bowl or sealed bag. Add the marinade ingredients, ensuring everything is well coated. Refrigerate for the recommended time — longer marinating means deeper flavor."
            }
            return "Ensure the ingredient is evenly covered on all sides. Pat dry first if coating with dry ingredients — moisture prevents proper adhesion."

        case .knead:
            return "Push the dough away from you with the heel of your palm, fold it back, rotate 90°, and repeat. Knead for 8-10 minutes until the dough is smooth and elastic — it should bounce back when poked."

        case .rest:
            return "Leave the food undisturbed at the specified temperature. Resting allows juices to redistribute (for meats) or gluten to relax (for doughs). Cover loosely to prevent drying."

        case .serve:
            if lower.contains("garnish") {
                return "Add the finishing touches right before serving. Place garnish on top for visual appeal — fresh herbs, a squeeze of lemon, or a drizzle of sauce elevates the presentation."
            }
            return "Transfer to a serving plate or bowl. For best presentation, use warm plates for hot food. Arrange neatly and add any final touches."

        case .cook:
            if lower.contains("until") {
                let cue = extractVisualCue(from: instruction)
                return "Continue cooking while watching for the visual cue: \(cue). Stay attentive and adjust heat as needed — the timing depends on your specific stove and cookware."
            }
            return "Continue cooking at the specified heat level. Watch for visual and aromatic cues that indicate the food is ready."

        case .general:
            return "Follow the instruction as described. Take your time and prepare everything before moving to the next step."
        }
    }

    // MARK: - Pro Tips

    private static func generateTips(instruction: String, action: CookingAction, ingredients: [String]) -> [String] {
        var tips: [String] = []
        let lower = instruction.lowercased()

        // Action-based tips
        switch action {
        case .prep:
            tips.append("A sharp knife is safer than a dull one — it requires less force and is less likely to slip.")
            if lower.contains("onion") {
                tips.append("💧 Chill the onion in the freezer for 10 min before cutting to reduce tears.")
            }
            if lower.contains("garlic") {
                tips.append("Crush garlic cloves with the flat side of a knife first — the skin peels off easily.")
            }

        case .mix:
            if lower.contains("dry") || lower.contains("flour") {
                tips.append("Sift flour before mixing to remove lumps and aerate it for a lighter result.")
            }
            if lower.contains("egg") || lower.contains("wet") {
                tips.append("Room-temperature eggs incorporate more evenly than cold ones.")
            }
            tips.append("Don't overmix batters — a few small lumps are perfectly fine and keep the texture light.")

        case .fry, .stirFry:
            tips.append("Pat ingredients dry before adding to hot oil — water causes dangerous spattering.")
            tips.append("Don't overcrowd the pan — cook in batches if needed for a proper sear.")
            if lower.contains("onion") {
                tips.append("Stir onions every 30 seconds. Golden brown takes about 5-7 minutes on medium heat.")
            }

        case .heat:
            tips.append("Test oil temperature by dropping a tiny piece of ingredient in — it should sizzle immediately.")
            if lower.contains("butter") {
                tips.append("Watch butter carefully — it goes from golden-brown to burnt very quickly.")
            }

        case .simmer:
            tips.append("Adjust heat as needed — the goal is gentle bubbles, not a vigorous boil.")
            tips.append("A lid slightly ajar lets steam escape while retaining heat.")

        case .boil:
            tips.append("Salt the water generously — it should 'taste like the sea' for pasta and vegetables.")
            tips.append("A watched pot does boil — cover it to speed up the process.")

        case .bake:
            tips.append("Use the middle rack for the most even heat distribution.")
            tips.append("Invest in an oven thermometer — many ovens run hotter or cooler than displayed.")

        case .knead:
            tips.append("If dough sticks, lightly flour your hands — not the board (too much flour makes it tough).")
            tips.append("The windowpane test: stretch a small piece thin — if light passes through without tearing, it's ready.")

        case .serve:
            tips.append("Warm your plates in the oven at 170°F for 5 minutes for a restaurant-quality touch.")

        default:
            break
        }

        // Ingredient-specific tips
        for ingredient in ingredients {
            let ing = ingredient.lowercased()
            if ing.contains("paneer") {
                tips.append("Soak paneer in warm water for 10 min before cooking — it stays soft and doesn't become rubbery.")
            }
            if ing.contains("cream") {
                tips.append("Add cream off the heat or on low temperature to prevent it from curdling.")
            }
            if ing.contains("tomato") {
                tips.append("Cook tomatoes until the oil separates — this is the sign that the raw taste is gone.")
            }
            if ing.contains("spice") || ing.contains("masala") {
                tips.append("Add ground spices to oil/fat first (blooming) to release their full aroma.")
            }
            if ing.contains("ginger") || ing.contains("garlic") {
                tips.append("Don't burn garlic — it turns bitter in seconds. Add it after onions start softening.")
            }
        }

        // Duration-specific tips
        if lower.contains("minute") || lower.contains("min") {
            tips.append("⏱️ Set a timer! It's easy to lose track and overcook.")
        }

        // Limit to 3 most relevant tips
        return Array(tips.prefix(3))
    }

    // MARK: - Helpers

    private static func extractIngredientsFromStep(_ text: String) -> [String] {
        var found: [String] = []
        let ingredientKeywords = [
            "flour", "sugar", "baking powder", "baking soda", "salt",
            "butter", "oil", "milk", "cream", "egg", "eggs",
            "onion", "onions", "garlic", "ginger", "tomato", "tomatoes",
            "chicken", "paneer", "beef", "lamb", "fish", "shrimp",
            "rice", "pasta", "noodles", "water", "broth", "stock",
            "cheese", "yogurt", "curd", "ghee",
            "pepper", "cumin", "turmeric", "coriander", "cilantro",
            "chili", "garam masala", "paprika", "cinnamon",
            "lemon", "lime", "vinegar", "soy sauce",
            "mushroom", "mushrooms", "spinach", "potato", "potatoes",
            "carrot", "carrots", "peas", "corn", "beans",
            "coconut milk", "coconut", "vanilla", "chocolate", "cocoa",
            "honey", "maple syrup", "yeast",
            "spices", "seasoning", "herbs"
        ]

        // Multi-word first
        let sorted = ingredientKeywords.sorted { $0.count > $1.count }
        for keyword in sorted {
            if text.contains(keyword) && !found.contains(keyword.capitalized) {
                found.append(keyword.capitalized)
            }
        }

        return found
    }

    private static func extractVisualCue(from instruction: String) -> String {
        let lower = instruction.lowercased()
        if let range = lower.range(of: "until ") {
            let cue = String(lower[range.upperBound...]).trimmingCharacters(in: .punctuationCharacters)
            return cue.isEmpty ? "the desired result is achieved" : cue
        }
        return "it looks and smells ready"
    }
}
