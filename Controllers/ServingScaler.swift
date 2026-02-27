import Foundation

enum RecipeCategory: String, CaseIterable {
    case cake
    case bread
    case rice
    case pasta
    case curry
    case salad
    case soup
    case general

    /// Detect category from recipe name and step text
    static func detect(name: String, steps: [String]) -> RecipeCategory {
        let combined = (name + " " + steps.joined(separator: " ")).lowercased()

        if combined.contains("cake") || combined.contains("brownie") || combined.contains("muffin") || combined.contains("cupcake") {
            return .cake
        }
        if combined.contains("bread") || combined.contains("loaf") || combined.contains("bun") || combined.contains("roll") {
            return .bread
        }
        if combined.contains("rice") || combined.contains("biryani") || combined.contains("pulao") || combined.contains("fried rice") {
            return .rice
        }
        if combined.contains("pasta") || combined.contains("spaghetti") || combined.contains("noodle") || combined.contains("macaroni") {
            return .pasta
        }
        if combined.contains("curry") || combined.contains("masala") || combined.contains("stew") || combined.contains("dal") || combined.contains("gravy") {
            return .curry
        }
        if combined.contains("salad") {
            return .salad
        }
        if combined.contains("soup") || combined.contains("broth") || combined.contains("chowder") {
            return .soup
        }
        return .general
    }

    /// Base unit label for this category
    var unitLabel: String {
        switch self {
        case .cake, .bread: return "pound"
        case .rice: return "cup"
        case .pasta: return "serving"
        case .curry, .soup: return "serving"
        case .salad: return "serving"
        case .general: return "serving"
        }
    }

    /// Preset scale options
    var presets: [(label: String, multiplier: Double)] {
        switch self {
        case .cake:
            return [
                ("½ lb", 0.5),
                ("1 lb", 1.0),
                ("2 lb", 2.0),
                ("3 lb", 3.0),
                ("5 lb", 5.0)
            ]
        case .bread:
            return [
                ("1 loaf", 1.0),
                ("2 loaves", 2.0),
                ("3 loaves", 3.0)
            ]
        case .rice:
            return [
                ("1 cup", 1.0),
                ("2 cups", 2.0),
                ("3 cups", 3.0),
                ("5 cups", 5.0)
            ]
        case .pasta:
            return [
                ("1 serving", 1.0),
                ("2 servings", 2.0),
                ("4 servings", 4.0),
                ("6 servings", 6.0)
            ]
        case .curry, .soup:
            return [
                ("1 serving", 1.0),
                ("2 servings", 2.0),
                ("4 servings", 4.0),
                ("6 servings", 6.0)
            ]
        case .salad:
            return [
                ("1 serving", 1.0),
                ("2 servings", 2.0),
                ("4 servings", 4.0)
            ]
        case .general:
            return [
                ("1×", 1.0),
                ("2×", 2.0),
                ("3×", 3.0),
                ("4×", 4.0)
            ]
        }
    }
}

struct ServingScaler {

    /// Scale a quantity string by a multiplier
    /// e.g. "2 cups" × 3 = "6 cups", "500g" × 2 = "1000g"
    static func scale(quantity: String, by multiplier: Double) -> String {
        guard multiplier != 1.0 else { return quantity }

        if quantity == "As needed" { return quantity }

        // Try to extract numeric value and unit
        let pattern = #"^(\d+\.?\d*)\s*(.*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: quantity, range: NSRange(quantity.startIndex..., in: quantity)) else {
            return quantity
        }

        guard let numRange = Range(match.range(at: 1), in: quantity),
              let value = Double(quantity[numRange]) else {
            return quantity
        }

        let unit: String
        if let unitRange = Range(match.range(at: 2), in: quantity) {
            unit = String(quantity[unitRange]).trimmingCharacters(in: .whitespaces)
        } else {
            unit = ""
        }

        let scaled = value * multiplier

        // Format nicely: remove ".0" for whole numbers
        let formatted: String
        if scaled.truncatingRemainder(dividingBy: 1) == 0 {
            formatted = String(Int(scaled))
        } else {
            formatted = String(format: "%.1f", scaled)
        }

        return unit.isEmpty ? formatted : "\(formatted) \(unit)"
    }

    /// Parse a fraction string like "1/2" or "0.5" into a Double
    static func parseFraction(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        // Try fractions like "1/2"
        if trimmed.contains("/") {
            let parts = trimmed.split(separator: "/")
            if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]), den != 0 {
                return num / den
            }
        }

        // Try decimals
        return Double(trimmed)
    }
}
