import Foundation

/// One entry in the life log — a meal, a movement, a med taken, or a moment.
/// Every entry gets a face: a studio image matched from what the user typed.
struct CareEntry: Identifiable, Equatable, Codable {
    enum Kind: String, CaseIterable, Identifiable, Codable {
        case meal = "Meals"
        case move = "Moves"
        case med = "Meds"

        var id: String { rawValue }

        var glyph: String {
            switch self {
            case .meal: return "fork.knife"
            case .move: return "figure.walk"
            case .med: return "pills"
            }
        }

        var displayName: String {
            switch self {
            case .meal: return "Meals"
            case .move: return "Activity"
            case .med: return "Meds"
            }
        }

        var addPrompt: String {
            switch self {
            case .meal: return "What did you eat?"
            case .move: return "How were you active?"
            case .med: return "Which one did you take?"
            }
        }
    }

    var id = UUID()
    let kind: Kind
    var title: String
    var detail: String
    var at: Date
    /// Bundled studio-image name from `LifeLibrary.match`.
    var imageName: String
    var note: String? = nil
    var linkedMedID: String? = nil

    /// Estimated nutrition (meals) or effort (activity) for the entry's image.
    var facts: LifeFacts? { LifeLibrary.facts(for: imageName) }
}

/// Studio-estimate nutrition and effort — honest "about" numbers, never
/// presented as lab truth.
struct LifeFacts: Equatable {
    var calories: Int = 0
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0
    var portion: String = ""
    /// Activity: minutes of gentle effort.
    var minutes: Int = 0
}

/// Matches free text to the bundled studio-photography library so every
/// logged thing gets a consistent, beautiful face.
enum LifeLibrary {
    struct Match {
        let imageName: String
        let suggestedTitle: String
    }

    /// One browsable entry in the food or activity library. Every item reuses
    /// the existing studio photography so the catalog stays visually coherent.
    struct LibraryItem: Identifiable, Equatable, Hashable {
        var id: String { name }
        let name: String
        let image: String
        /// Meal slot (Breakfast/Lunch/Dinner/Snack) or activity family.
        let group: String
    }

    /// The full, browsable, vegetarian-forward food library across every slot.
    static let foods: [LibraryItem] = [
        // Breakfast
        LibraryItem(name: "Oatmeal & berries", image: "oatmeal_bowl_blueberries", group: "Breakfast"),
        LibraryItem(name: "Overnight oats", image: "oatmeal_bowl_blueberries", group: "Breakfast"),
        LibraryItem(name: "Granola & yogurt", image: "yogurt_parfait_glass", group: "Breakfast"),
        LibraryItem(name: "Greek yogurt parfait", image: "yogurt_parfait_glass", group: "Breakfast"),
        LibraryItem(name: "Veggie omelette", image: "vegetable_omelette_plate", group: "Breakfast"),
        LibraryItem(name: "Tofu scramble", image: "vegetable_omelette_plate", group: "Breakfast"),
        LibraryItem(name: "Avocado toast", image: "vegetable_omelette_plate", group: "Breakfast"),
        LibraryItem(name: "Shakshuka", image: "vegetable_omelette_plate", group: "Breakfast"),
        LibraryItem(name: "Chia pudding", image: "yogurt_parfait_glass", group: "Breakfast"),
        LibraryItem(name: "Banana-berry smoothie", image: "yogurt_parfait_glass", group: "Breakfast"),
        // Lunch
        LibraryItem(name: "Quinoa grain bowl", image: "grain_bowl_chicken_quinoa", group: "Lunch"),
        LibraryItem(name: "Buddha bowl", image: "grain_bowl_chicken_quinoa", group: "Lunch"),
        LibraryItem(name: "Chickpea salad", image: "grilled_salmon_lemon_greens", group: "Lunch"),
        LibraryItem(name: "Greek salad", image: "grilled_salmon_lemon_greens", group: "Lunch"),
        LibraryItem(name: "Caprese salad", image: "grilled_salmon_lemon_greens", group: "Lunch"),
        LibraryItem(name: "Hummus mezze plate", image: "grain_bowl_chicken_quinoa", group: "Lunch"),
        LibraryItem(name: "Falafel wrap", image: "grain_bowl_chicken_quinoa", group: "Lunch"),
        LibraryItem(name: "Veggie burrito bowl", image: "grain_bowl_chicken_quinoa", group: "Lunch"),
        LibraryItem(name: "Lentil soup", image: "lentil_soup_bowl", group: "Lunch"),
        LibraryItem(name: "Minestrone", image: "lentil_soup_bowl", group: "Lunch"),
        LibraryItem(name: "Tomato soup", image: "lentil_soup_bowl", group: "Lunch"),
        // Dinner
        LibraryItem(name: "Tofu & veg stir-fry", image: "grain_bowl_chicken_quinoa", group: "Dinner"),
        LibraryItem(name: "Paneer tikka & rice", image: "grain_bowl_chicken_quinoa", group: "Dinner"),
        LibraryItem(name: "Chickpea curry & rice", image: "lentil_soup_bowl", group: "Dinner"),
        LibraryItem(name: "Dal & brown rice", image: "lentil_soup_bowl", group: "Dinner"),
        LibraryItem(name: "Veggie chili", image: "lentil_soup_bowl", group: "Dinner"),
        LibraryItem(name: "Vegetable curry", image: "lentil_soup_bowl", group: "Dinner"),
        LibraryItem(name: "Black bean tacos", image: "lentil_soup_bowl", group: "Dinner"),
        LibraryItem(name: "Grilled salmon & greens", image: "grilled_salmon_lemon_greens", group: "Dinner"),
        LibraryItem(name: "Veggie pasta", image: "grain_bowl_chicken_quinoa", group: "Dinner"),
        LibraryItem(name: "Roasted veg & quinoa", image: "grain_bowl_chicken_quinoa", group: "Dinner"),
        LibraryItem(name: "Eggplant parm", image: "grain_bowl_chicken_quinoa", group: "Dinner"),
        LibraryItem(name: "Stuffed peppers", image: "grain_bowl_chicken_quinoa", group: "Dinner"),
        // Snack
        LibraryItem(name: "Berry smoothie", image: "yogurt_parfait_glass", group: "Snack"),
        LibraryItem(name: "Yogurt & fruit", image: "yogurt_parfait_glass", group: "Snack"),
        LibraryItem(name: "Apple & nut butter", image: "yogurt_parfait_glass", group: "Snack"),
        LibraryItem(name: "Hummus & veg", image: "grain_bowl_chicken_quinoa", group: "Snack"),
        LibraryItem(name: "Trail mix", image: "yogurt_parfait_glass", group: "Snack"),
        LibraryItem(name: "Cottage cheese & fruit", image: "yogurt_parfait_glass", group: "Snack"),
    ]

    /// The full, browsable activity library — walking through gardening.
    /// Every activity carries its own soft clay-render illustration (Currents
    /// style) so the picker never repeats the same face.
    static let activities: [LibraryItem] = [
        LibraryItem(name: "Walk", image: "walking_shoes_stride", group: "Moving"),
        LibraryItem(name: "Evening walk", image: "walking_shoes_stride", group: "Moving"),
        LibraryItem(name: "Morning walk", image: "walking_shoes_stride", group: "Moving"),
        LibraryItem(name: "Hike", image: "hiking_boots_walking_pole", group: "Moving"),
        LibraryItem(name: "Bike ride", image: "clay_bicycle", group: "Moving"),
        LibraryItem(name: "Cycling", image: "clay_bicycle", group: "Moving"),
        LibraryItem(name: "Swim", image: "water_ripples_goggles", group: "Moving"),
        LibraryItem(name: "Treadmill", image: "clay_treadmill", group: "Moving"),
        LibraryItem(name: "Stairs", image: "clay_stairs_glow", group: "Moving"),
        LibraryItem(name: "Yoga", image: "yoga_mat_bolster", group: "Gentle"),
        LibraryItem(name: "Stretching", image: "clay_figure_stretching", group: "Gentle"),
        LibraryItem(name: "Pilates", image: "pilates_ring_and_mat", group: "Gentle"),
        LibraryItem(name: "Tai chi", image: "clay_figure_tai_chi", group: "Gentle"),
        LibraryItem(name: "Breathing", image: "glowing_clay_orb", group: "Gentle"),
        LibraryItem(name: "Dance", image: "clay_figure_dancing", group: "Gentle"),
        LibraryItem(name: "Strength training", image: "clay_dumbbells", group: "Strength"),
        LibraryItem(name: "Resistance bands", image: "resistance_band_clay", group: "Strength"),
        LibraryItem(name: "Light weights", image: "kettlebell_clay", group: "Strength"),
        LibraryItem(name: "Quad sets", image: "leg_quad_extension", group: "Strength"),
        LibraryItem(name: "Physical therapy", image: "hands_supporting_knee", group: "Strength"),
        LibraryItem(name: "Gardening", image: "hands_planting_sprout", group: "Around home"),
        LibraryItem(name: "Yard work", image: "leaf_rake_with_pile", group: "Around home"),
        LibraryItem(name: "Housework", image: "broom_dustpan", group: "Around home"),
        LibraryItem(name: "Standing desk", image: "standing_desk_workspace", group: "Around home"),
    ]

    static func library(for kind: CareEntry.Kind) -> [LibraryItem] {
        kind == .meal ? foods : (kind == .move ? activities : [])
    }

    /// Symptom name → its soft editorial feeling-illustration (Currents style).
    /// These map to the bundled studio illustrations generated for feelings.
    static func feelingImage(for symptom: String) -> String {
        let l = symptom.lowercased()
        if l.contains("nausea") || l.contains("queas") { return "belly_stomach_relief" }
        if l.contains("appetite") { return "ceramic_bowl_glow" }
        if l.contains("fever") || l.contains("chill") { return "thermometer_warmth" }
        if l.contains("mouth") || l.contains("sore") { return "lips_mouth_tender" }
        if l.contains("tingl") || l.contains("numb") || l.contains("foot") || l.contains("feet") { return "hand_sparkles_tingling" }
        if l.contains("cramp") { return "leg_cramp_muscle" }
        if l.contains("knee") { return "knee_joint_pain" }
        if l.contains("swell") { return "joint_swelling_glow" }
        if l.contains("stiff") { return "hinge_joint_clay" }
        if l.contains("head") { return "clay_head_silhouette_glow" }
        if l.contains("dizz") { return "spiral_light_mist" }
        if l.contains("sleep") { return "moon_waves_stars_sleep" }
        if l.contains("stress") { return "thread_unwinding_light" }
        if l.contains("worry") || l.contains("anx") { return "soft_editorial_3d" }
        if l.contains("energy") || l.contains("fatigue") || l.contains("tired") { return "glowing_orb_in_leaves" }
        if l.contains("pain") { return "knee_joint_pain" }
        return "glowing_orb_in_leaves"
    }

    /// keyword sets → bundled image. Vegetarian-forward rows are listed first
    /// so a "tofu bowl" wins over the generic "bowl" / "rice" fallbacks.
    private static let mealTable: [(keys: [String], image: String, title: String)] = [
        (["tofu", "tempeh", "stir-fry", "stir fry", "paneer", "tikka", "buddha bowl", "veggie bowl", "veg bowl"], "grain_bowl_chicken_quinoa", "Tofu & veg bowl"),
        (["chickpea", "chana", "channa", "curry", "dal", "daal", "rajma", "masala"], "lentil_soup_bowl", "Chickpea curry"),
        (["hummus", "falafel", "mezze", "pita", "wrap", "burrito"], "grain_bowl_chicken_quinoa", "Mezze plate"),
        (["pasta", "risotto", "gnocchi", "penne", "spaghetti", "noodle", "ramen", "udon"], "grain_bowl_chicken_quinoa", "Veggie pasta"),
        (["avocado", "toast", "bagel", "english muffin"], "vegetable_omelette_plate", "Avocado toast"),
        (["smoothie", "shake", "banana", "mango", "berries", "berry"], "yogurt_parfait_glass", "Berry smoothie"),
        (["caprese", "mozzarella", "greek salad", "cobb", "caesar", "garden salad"], "grilled_salmon_lemon_greens", "Garden salad"),
        (["minestrone", "miso", "veg soup", "vegetable soup", "tomato soup", "pumpkin soup"], "lentil_soup_bowl", "Vegetable soup"),
        (["shakshuka", "veggie scramble", "tofu scramble"], "vegetable_omelette_plate", "Veggie scramble"),
        (["oat", "porridge", "granola", "muesli", "cereal", "breakfast bowl", "overnight oats"], "oatmeal_bowl_blueberries", "Oatmeal & berries"),
        (["salmon", "fish", "tuna", "seafood", "shrimp"], "grilled_salmon_lemon_greens", "Salmon & greens"),
        (["chicken", "bowl", "quinoa", "rice", "grain", "lunch"], "grain_bowl_chicken_quinoa", "Grain bowl"),
        (["egg", "omelet", "omelette", "frittata", "scramble"], "vegetable_omelette_plate", "Veggie omelette"),
        (["soup", "lentil", "stew", "chili", "bean", "broth"], "lentil_soup_bowl", "Lentil soup"),
        (["yogurt", "parfait", "fruit", "snack", "cottage cheese"], "yogurt_parfait_glass", "Yogurt parfait"),
        (["salad", "greens", "veggie", "vegetable"], "grilled_salmon_lemon_greens", "Greens plate"),
    ]

    private static let moveTable: [(keys: [String], image: String, title: String)] = [
        (["physical therapy", "prehab", "rehab", " pt"], "hands_supporting_knee", "Physical therapy"),
        (["quad", "leg raise", "leg lift"], "leg_quad_extension", "Quad sets"),
        (["resistance", "band"], "resistance_band_clay", "Resistance bands"),
        (["kettlebell", "light weight", "dumbbell"], "kettlebell_clay", "Light weights"),
        (["strength", "gym", "lift", "weight"], "clay_dumbbells", "Strength work"),
        (["standing desk", "desk"], "standing_desk_workspace", "Standing desk"),
        (["yard", "rake", "leaves", "mow"], "leaf_rake_with_pile", "Yard work"),
        (["garden", "plant", "weeding"], "hands_planting_sprout", "Garden time"),
        (["house", "clean", "chore", "sweep", "vacuum", "tidy"], "broom_dustpan", "Housework"),
        (["treadmill"], "clay_treadmill", "Treadmill"),
        (["stair"], "clay_stairs_glow", "Stairs"),
        (["hike", "trail"], "hiking_boots_walking_pole", "A hike"),
        (["swim", "pool", "laps"], "water_ripples_goggles", "Swim"),
        (["bike", "cycle", "cycling", "spin", "ride"], "clay_bicycle", "A good ride"),
        (["dance", "zumba"], "clay_figure_dancing", "Dance"),
        (["tai chi"], "clay_figure_tai_chi", "Tai chi"),
        (["breath", "meditat"], "glowing_clay_orb", "Breathing"),
        (["pilates"], "pilates_ring_and_mat", "Pilates"),
        (["stretch", "mobility"], "clay_figure_stretching", "Stretching"),
        (["yoga"], "yoga_mat_bolster", "Yoga"),
        (["walk", "stroll", "steps"], "walking_shoes_stride", "A good walk"),
    ]

    /// Med id → bundled image. Falls back to the amber bottle.
    private static let medImages: [String: String] = [
        "metformin": "medicine_bottle_tablets",
        "lisinopril": "blister_pack_tablets",
        "atorvastatin": "medicine_bottle_pills",
        "ondansetron": "medicine_bottle_tablets",
        "dexamethasone": "blister_pack_tablets",
        "acetaminophen": "medicine_bottle_pills",
    ]

    static func matchMeal(_ text: String) -> Match {
        if let item = catalogMatch(text, in: foods) { return item }
        return match(text, table: mealTable, fallback: Match(imageName: "grain_bowl_chicken_quinoa", suggestedTitle: "A good plate"))
    }

    static func matchMove(_ text: String) -> Match {
        if let item = catalogMatch(text, in: activities) { return item }
        return match(text, table: moveTable, fallback: Match(imageName: "walking_shoes_stride", suggestedTitle: "Movement"))
    }

    /// An exact (case-insensitive) catalog name match wins over keyword guessing
    /// so a tapped library item always keeps its own studio image.
    private static func catalogMatch(_ text: String, in items: [LibraryItem]) -> Match? {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty, let item = items.first(where: { $0.name.lowercased() == lower })
        else { return nil }
        return Match(imageName: item.image, suggestedTitle: item.name)
    }

    static func medImage(for medID: String) -> String {
        medImages[medID] ?? "medicine_bottle_pills"
    }

    /// Image → estimated facts. Meals carry macros; activity carries minutes.
    private static let factsTable: [String: LifeFacts] = [
        "oatmeal_bowl_blueberries": LifeFacts(calories: 320, protein: 12, carbs: 54, fat: 8, portion: "1 warm bowl"),
        "grain_bowl_chicken_quinoa": LifeFacts(calories: 520, protein: 38, carbs: 52, fat: 16, portion: "1 hearty bowl"),
        "grilled_salmon_lemon_greens": LifeFacts(calories: 460, protein: 42, carbs: 12, fat: 26, portion: "1 plate"),
        "vegetable_omelette_plate": LifeFacts(calories: 340, protein: 22, carbs: 8, fat: 24, portion: "2-egg omelette"),
        "lentil_soup_bowl": LifeFacts(calories: 310, protein: 18, carbs: 45, fat: 6, portion: "1 bowl"),
        "yogurt_parfait_glass": LifeFacts(calories: 280, protein: 14, carbs: 38, fat: 9, portion: "1 glass"),
        "terracotta_cream_sneakers": LifeFacts(portion: "an easy pace", minutes: 25),
        "yoga_mat_rolled": LifeFacts(portion: "breath first", minutes: 20),
        "dumbbells_towel_wellness": LifeFacts(portion: "steady sets", minutes: 30),
        "soft_editorial_studio": LifeFacts(portion: "hands in the dirt", minutes: 35),
        "walking_shoes_stride": LifeFacts(portion: "an easy pace", minutes: 25),
        "hiking_boots_walking_pole": LifeFacts(portion: "on the trail", minutes: 50),
        "clay_bicycle": LifeFacts(portion: "steady spin", minutes: 35),
        "water_ripples_goggles": LifeFacts(portion: "easy laps", minutes: 30),
        "clay_treadmill": LifeFacts(portion: "steady pace", minutes: 25),
        "clay_stairs_glow": LifeFacts(portion: "flight by flight", minutes: 12),
        "yoga_mat_bolster": LifeFacts(portion: "breath first", minutes: 25),
        "clay_figure_stretching": LifeFacts(portion: "gentle and slow", minutes: 15),
        "pilates_ring_and_mat": LifeFacts(portion: "core and control", minutes: 30),
        "clay_figure_tai_chi": LifeFacts(portion: "slow and flowing", minutes: 25),
        "glowing_clay_orb": LifeFacts(portion: "just breathe", minutes: 10),
        "clay_figure_dancing": LifeFacts(portion: "keep moving", minutes: 25),
        "clay_dumbbells": LifeFacts(portion: "steady sets", minutes: 30),
        "resistance_band_clay": LifeFacts(portion: "controlled reps", minutes: 20),
        "kettlebell_clay": LifeFacts(portion: "light and steady", minutes: 20),
        "leg_quad_extension": LifeFacts(portion: "slow holds", minutes: 12),
        "hands_supporting_knee": LifeFacts(portion: "the prescribed set", minutes: 25),
        "hands_planting_sprout": LifeFacts(portion: "hands in the dirt", minutes: 35),
        "leaf_rake_with_pile": LifeFacts(portion: "raking and tidying", minutes: 40),
        "broom_dustpan": LifeFacts(portion: "room by room", minutes: 30),
        "standing_desk_workspace": LifeFacts(portion: "on your feet", minutes: 60),
    ]

    static func facts(for imageName: String) -> LifeFacts? {
        factsTable[imageName]
    }

    private static func match(_ text: String,
                              table: [(keys: [String], image: String, title: String)],
                              fallback: Match) -> Match {
        let lower = text.lowercased()
        for row in table where row.keys.contains(where: { lower.contains($0) }) {
            return Match(imageName: row.image, suggestedTitle: text.isEmpty ? row.title : text)
        }
        return Match(imageName: fallback.imageName,
                     suggestedTitle: text.isEmpty ? fallback.suggestedTitle : text)
    }
}

/// An agentic step the companion can take on the user's behalf.
/// Critical actions wait for one human tap — always.
struct AgentAction: Identifiable, Equatable {
    enum State: Equatable { case proposed, done, declined }

    let id = UUID()
    let title: String
    let detail: String
    let outcomeLine: String
    let glyph: String
    /// True when the action sends something beyond the device.
    let leavesDevice: Bool
    var state: State = .proposed
}

/// A held moment — a photo inside a glass bubble. The garden of who you're
/// becoming, one small joy at a time.
struct MemoryGlimpse: Identifiable, Equatable, Codable {
    var id = UUID()
    /// Bundled asset name, or a file in Documents when user-captured.
    var imageName: String? = nil
    var photoFilename: String? = nil
    var caption: String
    var date: Date
}

/// The person behind the persona — collected warmly during onboarding,
/// used to match hospital records and to greet by name.
struct UserProfile: Codable, Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var birthDate: Date? = nil
    var healthConnected: Bool = false
    var connectedSystems: [String] = []

    var isComplete: Bool { !firstName.isEmpty }
}
