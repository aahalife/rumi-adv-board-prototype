import type { LifeFacts } from "./types";

/** Mirror of MarcusFixtures.date — a fixed calendar date at 10:00. */
export function d(year: number, month: number, day: number, hour = 10, minute = 0): number {
  return new Date(year, month - 1, day, hour, minute, 0).getTime();
}
export function daysAgo(n: number, hour = 10, minute = 0): number {
  const dt = new Date();
  dt.setDate(dt.getDate() - n);
  dt.setHours(hour, minute, 0, 0);
  return dt.getTime();
}
export function hoursAgo(n: number): number {
  return Date.now() - n * 3600_000;
}

let _id = 0;
export const uid = (prefix = "id"): string => `${prefix}_${(_id++).toString(36)}_${Math.random().toString(36).slice(2, 7)}`;

/** Resolve an asset name (bundled studio image) to a public URL. */
export function img(name?: string | null): string | null {
  if (!name) return null;
  // jpg-backed names (conditions, currents, recap), everything else png.
  const jpg = name.startsWith("condition_") || name.startsWith("currents_") || name.startsWith("recap_");
  return `/img/${name}.${jpg ? "jpg" : "png"}`;
}

interface Match { imageName: string; suggestedTitle: string }

export interface LibraryItem { name: string; image: string; group: string }

/** The full, browsable, vegetarian-forward food library across every slot. */
export const foods: LibraryItem[] = [
  { name: "Oatmeal & berries", image: "oatmeal_bowl_blueberries", group: "Breakfast" },
  { name: "Overnight oats", image: "oatmeal_bowl_blueberries", group: "Breakfast" },
  { name: "Granola & yogurt", image: "yogurt_parfait_glass", group: "Breakfast" },
  { name: "Greek yogurt parfait", image: "yogurt_parfait_glass", group: "Breakfast" },
  { name: "Veggie omelette", image: "vegetable_omelette_plate", group: "Breakfast" },
  { name: "Tofu scramble", image: "vegetable_omelette_plate", group: "Breakfast" },
  { name: "Avocado toast", image: "vegetable_omelette_plate", group: "Breakfast" },
  { name: "Shakshuka", image: "vegetable_omelette_plate", group: "Breakfast" },
  { name: "Chia pudding", image: "yogurt_parfait_glass", group: "Breakfast" },
  { name: "Banana-berry smoothie", image: "yogurt_parfait_glass", group: "Breakfast" },
  { name: "Quinoa grain bowl", image: "grain_bowl_chicken_quinoa", group: "Lunch" },
  { name: "Buddha bowl", image: "grain_bowl_chicken_quinoa", group: "Lunch" },
  { name: "Chickpea salad", image: "grilled_salmon_lemon_greens", group: "Lunch" },
  { name: "Greek salad", image: "grilled_salmon_lemon_greens", group: "Lunch" },
  { name: "Caprese salad", image: "grilled_salmon_lemon_greens", group: "Lunch" },
  { name: "Hummus mezze plate", image: "grain_bowl_chicken_quinoa", group: "Lunch" },
  { name: "Falafel wrap", image: "grain_bowl_chicken_quinoa", group: "Lunch" },
  { name: "Veggie burrito bowl", image: "grain_bowl_chicken_quinoa", group: "Lunch" },
  { name: "Lentil soup", image: "lentil_soup_bowl", group: "Lunch" },
  { name: "Minestrone", image: "lentil_soup_bowl", group: "Lunch" },
  { name: "Tomato soup", image: "lentil_soup_bowl", group: "Lunch" },
  { name: "Tofu & veg stir-fry", image: "grain_bowl_chicken_quinoa", group: "Dinner" },
  { name: "Paneer tikka & rice", image: "grain_bowl_chicken_quinoa", group: "Dinner" },
  { name: "Chickpea curry & rice", image: "lentil_soup_bowl", group: "Dinner" },
  { name: "Dal & brown rice", image: "lentil_soup_bowl", group: "Dinner" },
  { name: "Veggie chili", image: "lentil_soup_bowl", group: "Dinner" },
  { name: "Vegetable curry", image: "lentil_soup_bowl", group: "Dinner" },
  { name: "Black bean tacos", image: "lentil_soup_bowl", group: "Dinner" },
  { name: "Grilled salmon & greens", image: "grilled_salmon_lemon_greens", group: "Dinner" },
  { name: "Veggie pasta", image: "grain_bowl_chicken_quinoa", group: "Dinner" },
  { name: "Roasted veg & quinoa", image: "grain_bowl_chicken_quinoa", group: "Dinner" },
  { name: "Eggplant parm", image: "grain_bowl_chicken_quinoa", group: "Dinner" },
  { name: "Stuffed peppers", image: "grain_bowl_chicken_quinoa", group: "Dinner" },
  { name: "Berry smoothie", image: "yogurt_parfait_glass", group: "Snack" },
  { name: "Yogurt & fruit", image: "yogurt_parfait_glass", group: "Snack" },
  { name: "Apple & nut butter", image: "yogurt_parfait_glass", group: "Snack" },
  { name: "Hummus & veg", image: "grain_bowl_chicken_quinoa", group: "Snack" },
  { name: "Trail mix", image: "yogurt_parfait_glass", group: "Snack" },
  { name: "Cottage cheese & fruit", image: "yogurt_parfait_glass", group: "Snack" },
];

/** The full, browsable activity library — walking through gardening. */
export const activities: LibraryItem[] = [
  { name: "Walk", image: "terracotta_cream_sneakers", group: "Moving" },
  { name: "Evening walk", image: "terracotta_cream_sneakers", group: "Moving" },
  { name: "Morning walk", image: "terracotta_cream_sneakers", group: "Moving" },
  { name: "Hike", image: "terracotta_cream_sneakers", group: "Moving" },
  { name: "Bike ride", image: "terracotta_cream_sneakers", group: "Moving" },
  { name: "Cycling", image: "terracotta_cream_sneakers", group: "Moving" },
  { name: "Swim", image: "terracotta_cream_sneakers", group: "Moving" },
  { name: "Treadmill", image: "terracotta_cream_sneakers", group: "Moving" },
  { name: "Stairs", image: "terracotta_cream_sneakers", group: "Moving" },
  { name: "Yoga", image: "yoga_mat_rolled", group: "Gentle" },
  { name: "Stretching", image: "yoga_mat_rolled", group: "Gentle" },
  { name: "Pilates", image: "yoga_mat_rolled", group: "Gentle" },
  { name: "Tai chi", image: "yoga_mat_rolled", group: "Gentle" },
  { name: "Breathing", image: "yoga_mat_rolled", group: "Gentle" },
  { name: "Dance", image: "yoga_mat_rolled", group: "Gentle" },
  { name: "Strength training", image: "dumbbells_towel_wellness", group: "Strength" },
  { name: "Resistance bands", image: "dumbbells_towel_wellness", group: "Strength" },
  { name: "Light weights", image: "dumbbells_towel_wellness", group: "Strength" },
  { name: "Quad sets", image: "dumbbells_towel_wellness", group: "Strength" },
  { name: "Physical therapy", image: "dumbbells_towel_wellness", group: "Strength" },
  { name: "Gardening", image: "soft_editorial_studio", group: "Around home" },
  { name: "Yard work", image: "soft_editorial_studio", group: "Around home" },
  { name: "Housework", image: "soft_editorial_studio", group: "Around home" },
  { name: "Standing desk", image: "soft_editorial_studio", group: "Around home" },
];

/** Symptom name → its soft editorial feeling-illustration (Currents style). */
export function feelingImage(symptom: string): string {
  const l = symptom.toLowerCase();
  if (l.includes("nausea") || l.includes("queas")) return "belly_stomach_relief";
  if (l.includes("appetite")) return "ceramic_bowl_glow";
  if (l.includes("fever") || l.includes("chill")) return "thermometer_warmth";
  if (l.includes("mouth") || l.includes("sore")) return "lips_mouth_tender";
  if (l.includes("tingl") || l.includes("numb") || l.includes("foot") || l.includes("feet")) return "hand_sparkles_tingling";
  if (l.includes("cramp")) return "leg_cramp_muscle";
  if (l.includes("knee")) return "knee_joint_pain";
  if (l.includes("swell")) return "joint_swelling_glow";
  if (l.includes("stiff")) return "hinge_joint_clay";
  if (l.includes("head")) return "clay_head_silhouette_glow";
  if (l.includes("dizz")) return "spiral_light_mist";
  if (l.includes("sleep")) return "moon_waves_stars_sleep";
  if (l.includes("stress")) return "thread_unwinding_light";
  if (l.includes("worry") || l.includes("anx")) return "soft_editorial_3d";
  if (l.includes("energy") || l.includes("fatigue") || l.includes("tired")) return "glowing_orb_in_leaves";
  if (l.includes("pain")) return "knee_joint_pain";
  return "glowing_orb_in_leaves";
}

const mealTable: { keys: string[]; image: string; title: string }[] = [
  { keys: ["oat", "porridge", "granola", "cereal", "breakfast bowl"], image: "oatmeal_bowl_blueberries", title: "Oatmeal & berries" },
  { keys: ["salmon", "fish", "tuna", "seafood", "shrimp"], image: "grilled_salmon_lemon_greens", title: "Salmon & greens" },
  { keys: ["chicken", "bowl", "quinoa", "rice", "grain", "burrito", "lunch"], image: "grain_bowl_chicken_quinoa", title: "Grain bowl" },
  { keys: ["egg", "omelet", "omelette", "frittata", "scramble"], image: "vegetable_omelette_plate", title: "Veggie omelette" },
  { keys: ["soup", "lentil", "stew", "dal", "chili", "broth"], image: "lentil_soup_bowl", title: "Lentil soup" },
  { keys: ["yogurt", "parfait", "berr", "smoothie", "fruit", "snack"], image: "yogurt_parfait_glass", title: "Yogurt parfait" },
  { keys: ["salad", "greens", "veggie", "vegetable"], image: "grilled_salmon_lemon_greens", title: "Greens plate" },
];

const moveTable: { keys: string[]; image: string; title: string }[] = [
  { keys: ["walk", "stroll", "steps", "hike"], image: "terracotta_cream_sneakers", title: "A good walk" },
  { keys: ["yoga", "stretch", "pilates", "breath"], image: "yoga_mat_rolled", title: "Yoga & stretch" },
  { keys: ["garden", "yard", "plant", "outdoor"], image: "soft_editorial_studio", title: "Garden time" },
  { keys: ["weight", "strength", "gym", "lift", "exercise", "quad", "prehab", "pt"], image: "dumbbells_towel_wellness", title: "Strength work" },
];

const medImages: Record<string, string> = {
  metformin: "medicine_bottle_tablets",
  lisinopril: "blister_pack_tablets",
  atorvastatin: "medicine_bottle_pills",
  ondansetron: "medicine_bottle_tablets",
  dexamethasone: "blister_pack_tablets",
  acetaminophen: "medicine_bottle_pills",
};

function matchTable(text: string, table: typeof mealTable, fallback: Match): Match {
  const lower = text.toLowerCase();
  for (const row of table) {
    if (row.keys.some((k) => lower.includes(k))) {
      return { imageName: row.image, suggestedTitle: text.trim() === "" ? row.title : text };
    }
  }
  return { imageName: fallback.imageName, suggestedTitle: text.trim() === "" ? fallback.suggestedTitle : text };
}

function catalogMatch(text: string, items: LibraryItem[]): Match | null {
  const lower = text.toLowerCase().trim();
  if (!lower) return null;
  const item = items.find((i) => i.name.toLowerCase() === lower);
  return item ? { imageName: item.image, suggestedTitle: item.name } : null;
}

export const LifeLibrary = {
  matchMeal: (t: string): Match => catalogMatch(t, foods) ?? matchTable(t, mealTable, { imageName: "grain_bowl_chicken_quinoa", suggestedTitle: "A good plate" }),
  matchMove: (t: string): Match => catalogMatch(t, activities) ?? matchTable(t, moveTable, { imageName: "terracotta_cream_sneakers", suggestedTitle: "Activity" }),
  medImage: (id: string): string => medImages[id] ?? "medicine_bottle_pills",
  facts: (imageName: string): LifeFacts | null => factsTable[imageName] ?? null,
  library: (kind: string): LibraryItem[] => (kind === "Meals" ? foods : kind === "Moves" ? activities : []),
};

const factsTable: Record<string, LifeFacts> = {
  oatmeal_bowl_blueberries: { calories: 320, protein: 12, carbs: 54, fat: 8, portion: "1 warm bowl" },
  grain_bowl_chicken_quinoa: { calories: 520, protein: 38, carbs: 52, fat: 16, portion: "1 hearty bowl" },
  grilled_salmon_lemon_greens: { calories: 460, protein: 42, carbs: 12, fat: 26, portion: "1 plate" },
  vegetable_omelette_plate: { calories: 340, protein: 22, carbs: 8, fat: 24, portion: "2-egg omelette" },
  lentil_soup_bowl: { calories: 310, protein: 18, carbs: 45, fat: 6, portion: "1 bowl" },
  yogurt_parfait_glass: { calories: 280, protein: 14, carbs: 38, fat: 9, portion: "1 glass" },
  terracotta_cream_sneakers: { portion: "an easy pace", minutes: 25 },
  yoga_mat_rolled: { portion: "breath first", minutes: 20 },
  dumbbells_towel_wellness: { portion: "steady sets", minutes: 30 },
  soft_editorial_studio: { portion: "hands in the dirt", minutes: 35 },
};

export function capFirst(s: string): string {
  return s.length === 0 ? s : s[0].toUpperCase() + s.slice(1);
}

export const fmtTime = (ts: number): string =>
  new Date(ts).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
export const fmtMonthDay = (ts: number): string =>
  new Date(ts).toLocaleDateString([], { month: "short", day: "numeric" });
export const fmtWeekday = (ts: number): string =>
  new Date(ts).toLocaleDateString([], { weekday: "long" });
