import Foundation

/// Fixture corpus — the entire app builds against Marcus, 54, Atlanta.
/// T2D (A1c 8.4), hypertension, CKD-2. Metformin, lisinopril, atorvastatin.
/// Single father, warehouse ops manager, Braves fan, financially stretched,
/// low patience for apps that judge him.
enum MarcusFixtures {

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 10
        return Calendar.current.date(from: components) ?? .now
    }

    // MARK: Lab series

    static let labSeries: [LabSeries] = [
        LabSeries(
            id: "a1c",
            name: "A1c",
            unit: "%",
            points: [
                LabPoint(date: date(2025, 3, 18), value: 9.4),
                LabPoint(date: date(2025, 6, 10), value: 9.1),
                LabPoint(date: date(2025, 9, 22), value: 8.9),
                LabPoint(date: date(2025, 12, 15), value: 8.7),
                LabPoint(date: date(2026, 3, 12), value: 8.4),
            ],
            band: 4.5...7.0,
            bandLabel: "where your care team wants this heading",
            annotation: SeriesAnnotation(date: date(2025, 6, 10), label: "metformin steadied here"),
            provenance: "From your Mar 12 Piedmont lab",
            explainReading: "A1c is a 3-month average of your blood sugar. Yours is 8.4% — still above where your care team wants it, but it has moved down five readings in a row. That direction matters more than any single number.",
            explainNextStep: "Keep doing what's working — steady metformin and the evening walks. Your next draw is around September; if the slide continues you'll be under 8 for the first time in three years.",
            explainAsk: "Want me to put this trend on your visit-prep for Dr. Patterson on June 24?"
        ),
        LabSeries(
            id: "egfr",
            name: "eGFR",
            unit: "mL/min",
            points: [
                LabPoint(date: date(2025, 3, 18), value: 78),
                LabPoint(date: date(2025, 9, 22), value: 75),
                LabPoint(date: date(2026, 3, 12), value: 74),
            ],
            band: 60...90,
            bandLabel: "stage-2 range",
            annotation: nil,
            provenance: "From your Mar 12 Piedmont lab",
            explainReading: "eGFR estimates how well your kidneys filter. 74 keeps you in stage 2 — mild, and holding steady. Explained with your kidney function in mind: stability is the win here.",
            explainNextStep: "Lisinopril is doing protective work. Staying hydrated on warehouse shifts and easy on ibuprofen are the two things most in your control.",
            explainAsk: "Want a heads-up before each kidney panel so it never sneaks up on you?"
        ),
        LabSeries(
            id: "bp",
            name: "Home blood pressure",
            unit: "mmHg",
            points: [
                LabPoint(date: date(2026, 6, 4), value: 138),
                LabPoint(date: date(2026, 6, 5), value: 134),
                LabPoint(date: date(2026, 6, 6), value: 131),
                LabPoint(date: date(2026, 6, 7), value: 132),
                LabPoint(date: date(2026, 6, 8), value: 129),
                LabPoint(date: date(2026, 6, 9), value: 130),
                LabPoint(date: date(2026, 6, 10), value: 128),
            ],
            band: 110...130,
            bandLabel: "the calm zone",
            annotation: nil,
            provenance: "From your home cuff, synced this morning",
            explainReading: "These are your systolic readings this week — the steadiest they've been in a month, drifting down toward the calm zone.",
            explainNextStep: "Nothing to change. The evening walks and steady lisinopril are exactly the recipe behind a week like this.",
            explainAsk: "Want me to flag the next time a rough night shows up in these numbers?"
        ),
        LabSeries(
            id: "ldl",
            name: "LDL cholesterol",
            unit: "mg/dL",
            points: [
                LabPoint(date: date(2025, 3, 18), value: 131),
                LabPoint(date: date(2025, 9, 22), value: 112),
                LabPoint(date: date(2026, 3, 12), value: 96),
            ],
            band: 50...100,
            bandLabel: "target with your history",
            annotation: SeriesAnnotation(date: date(2025, 3, 18), label: "started atorvastatin"),
            provenance: "From your Mar 12 Piedmont lab",
            explainReading: "LDL is the cholesterol worth watching. You've come from 131 to 96 in a year — that's the statin earning its keep.",
            explainNextStep: "Keep the atorvastatin steady. The refill due this week is the only thing between you and another good number.",
            explainAsk: "Want me to get Thursday's refill ready at CVS Peachtree?"
        ),
    ]

    // MARK: Medications

    static let medications: [Medication] = [
        Medication(
            id: "metformin",
            name: "Metformin",
            dose: "1000 mg · twice daily",
            purposeLine: "steadies your blood sugar",
            scheduleLine: "with breakfast and dinner",
            supplyDaysRemaining: 12,
            pharmacy: "CVS Peachtree",
            guidance: ["Take with food — easier on your stomach", "Skip the dose if you're ever told to fast for a scan; we'll plan around it"],
            watchlist: ["Stomach upset in the first weeks (yours settled in 2019)", "B12 gets checked yearly — last was fine in March"],
            history: ["1000 mg twice daily — since Jun 2025 (Dr. Patterson, after the 9.1 A1c)", "500 mg twice daily — 2019 to 2025"],
            adherence30: [1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1]
        ),
        Medication(
            id: "lisinopril",
            name: "Lisinopril",
            dose: "10 mg · once daily",
            purposeLine: "protects your kidneys and lowers BP",
            scheduleLine: "with breakfast",
            supplyDaysRemaining: 23,
            pharmacy: "CVS Peachtree",
            guidance: ["Morning is fine — consistency beats timing", "Go easy on ibuprofen; it works against this one and your kidneys"],
            watchlist: ["A dry cough is the known quirk — mention it if it shows up", "Potassium gets watched on your kidney panels"],
            history: ["10 mg daily — since 2024 (kidney-protective dose)", "5 mg daily — 2017 to 2024"],
            adherence30: [1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1]
        ),
        Medication(
            id: "atorvastatin",
            name: "Atorvastatin",
            dose: "20 mg · once daily",
            purposeLine: "keeps cholesterol in check",
            scheduleLine: "in the evening",
            supplyDaysRemaining: 5,
            pharmacy: "CVS Peachtree",
            guidance: ["Evening works best for this one", "No grapefruit juice in quantity — odd but true"],
            watchlist: ["Muscle cramps are worth telling me about — we watch this closely with your kidneys", "Liver panel rides along with your regular labs"],
            history: ["20 mg daily — since Mar 2025 (LDL was 131)"],
            adherence30: [1,1,0,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1]
        ),
    ]

    // MARK: Records drawer

    static let recordItems: [RecordItem] = [
        RecordItem(category: .labs, title: "A1c — 8.4%", detail: "Down from 8.7 in December", date: date(2026, 3, 12), source: "Piedmont · Privia", seriesID: "a1c"),
        RecordItem(category: .labs, title: "eGFR — 74", detail: "Stage 2, holding steady", date: date(2026, 3, 12), source: "Piedmont · Privia", seriesID: "egfr"),
        RecordItem(category: .labs, title: "LDL — 96", detail: "First time under 100", date: date(2026, 3, 12), source: "Piedmont · Privia", seriesID: "ldl"),
        RecordItem(category: .labs, title: "Potassium — 4.4", detail: "Comfortably normal", date: date(2026, 3, 12), source: "Piedmont · Privia"),
        RecordItem(category: .conditions, title: "Type 2 diabetes", detail: "Since 2019 · actively managed", date: date(2019, 8, 14), source: "Piedmont · Privia"),
        RecordItem(category: .conditions, title: "Hypertension", detail: "Since 2017 · trending calmer", date: date(2017, 5, 2), source: "Piedmont · Privia"),
        RecordItem(category: .conditions, title: "Chronic kidney disease, stage 2", detail: "Flagged 2024 · stable", date: date(2024, 4, 9), source: "Piedmont · Privia"),
        RecordItem(category: .medications, title: "Metformin 1000 mg", detail: "Active · twice daily", date: date(2025, 6, 10), source: "Piedmont · Privia"),
        RecordItem(category: .medications, title: "Lisinopril 10 mg", detail: "Active · once daily", date: date(2024, 4, 9), source: "Piedmont · Privia", conflicted: true, conflictNote: "Emory's list still shows 5 mg from 2023. Piedmont's 10 mg is current — want me to ask your care team to confirm?"),
        RecordItem(category: .medications, title: "Atorvastatin 20 mg", detail: "Active · evenings", date: date(2025, 3, 18), source: "Piedmont · Privia"),
        RecordItem(category: .immunizations, title: "Flu vaccine", detail: "Last: October 2025", date: date(2025, 10, 4), source: "CVS Peachtree"),
        RecordItem(category: .immunizations, title: "COVID-19 booster", detail: "Last: November 2025", date: date(2025, 11, 12), source: "CVS Peachtree"),
        RecordItem(category: .procedures, title: "Diabetic eye exam", detail: "Normal · repeat yearly", date: date(2025, 11, 20), source: "Emory · MyChart"),
        RecordItem(category: .notes, title: "Visit note — Dr. Patterson", detail: "\"Real progress. Keep the walking.\"", date: date(2026, 3, 12), source: "Piedmont · Privia"),
        RecordItem(category: .documents, title: "Insurance card", detail: "Scanned January 2026", date: date(2026, 1, 8), source: "You"),
    ]

    // MARK: Story

    static let storyEvents: [StoryEvent] = [
        StoryEvent(kind: .milestone, date: date(2026, 6, 8), title: "Steadiest BP week in a month", detail: "Seven readings, all drifting toward the calm zone."),
        StoryEvent(kind: .companion, date: date(2026, 5, 26), title: "We caught the cramp pattern", detail: "Leg cramps clustered on late-statin days — 4 of 5 times. Worth one question to Dr. Patterson."),
        StoryEvent(kind: .milestone, date: date(2026, 5, 14), title: "90 days of steady metformin", detail: "Quietly, one of the strongest things you've done this year."),
        StoryEvent(kind: .result, date: date(2026, 3, 12), title: "A1c 8.4 — fifth drop in a row", detail: "From 9.4 a year ago. Dr. Patterson: \"Real progress.\""),
        StoryEvent(kind: .visit, date: date(2026, 3, 12), title: "Visit — Dr. Patterson", detail: "Labs reviewed, plan unchanged, walking encouraged."),
        StoryEvent(kind: .result, date: date(2025, 12, 15), title: "A1c 8.7", detail: "The slide continued through the holidays — that's rare and real."),
        StoryEvent(kind: .milestone, date: date(2025, 9, 22), title: "LDL under 115 for the first time", detail: "Six months of atorvastatin showing up in the numbers."),
        StoryEvent(kind: .result, date: date(2025, 6, 10), title: "Metformin stepped up to 1000 mg", detail: "After the 9.1 — the turn this whole year built on."),
        StoryEvent(kind: .diagnosis, date: date(2024, 4, 9), title: "Kidneys flagged — stage 2", detail: "Caught early. Lisinopril moved to a protective dose."),
        StoryEvent(kind: .diagnosis, date: date(2019, 8, 14), title: "Type 2 diabetes", detail: "The diagnosis that started this story."),
        StoryEvent(kind: .diagnosis, date: date(2017, 5, 2), title: "Hypertension", detail: "Where the journey began."),
    ]

    // MARK: Insights

    static let insights: [Insight] = [
        Insight(
            category: .milestone,
            headline: "Your steadiest BP week in a month",
            body: "Seven mornings, every reading drifting down toward the calm zone. Weeks like this are what the evening walks and steady lisinopril were always for.",
            confidence: nil,
            provenance: "From your home cuff · 7 readings this week",
            actionLabel: "See the trend",
            status: .fresh,
            visual: .chart("bp"),
            sources: ["Home BP cuff via HealthKit (7 readings)", "Medication schedule (lisinopril, steady 30 days)"]
        ),
        Insight(
            category: .pattern,
            headline: "Cramps have clustered on late-statin days",
            body: "4 of the 5 times you logged leg cramps, the atorvastatin dose had drifted past 10pm. That's a pattern worth one question — not a conclusion.",
            confidence: "Based on 5 logs over 6 weeks — enough to notice, not enough to be sure.",
            provenance: "Your logs + dose timing · with your kidney function in mind",
            actionLabel: "Draft the question for Dr. Patterson",
            status: .seen,
            visual: .scene(7),
            sources: ["Symptom logs: leg cramps (5 entries)", "Atorvastatin dose times (30 days)", "CKD-2 on your problem list"]
        ),
        Insight(
            category: .headsUp,
            headline: "Atorvastatin runs out Thursday",
            body: "The refill is already ready at CVS Peachtree. One tap and it's waiting for you — or I can set up delivery so this stops being a thing you carry.",
            confidence: nil,
            provenance: "Pharmacy dispense data · CVS Peachtree",
            actionLabel: "Make it ready",
            status: .fresh,
            visual: .tide,
            sources: ["Surescripts dispense record (May 14 fill, 30-day supply)"]
        ),
        Insight(
            category: .opportunity,
            headline: "A screening window you've earned the right to ignore — but shouldn't",
            body: "You're 54. The USPSTF recommends colon cancer screening starting at 45, and there's nothing on your record yet. A take-home kit counts — no day off work required.",
            confidence: nil,
            provenance: "USPSTF guideline · your record shows no prior screening",
            actionLabel: "See the easy options",
            status: .seen,
            visual: .scene(12),
            sources: ["USPSTF colorectal screening recommendation (age 45–75)", "Your procedures history (no prior screening found)"]
        ),
        Insight(
            category: .pattern,
            headline: "Short nights show up in your next-morning readings",
            body: "On weeks with warehouse night shifts, your morning BP runs 6–8 points higher the day after. Your body keeps the receipts — gently.",
            confidence: "Seen in 3 of the last 4 shift weeks. We'll keep watching before calling it solid.",
            provenance: "Sleep via HealthKit + your home cuff",
            actionLabel: "Talk through shift weeks",
            status: .acted(outcome: "You moved Tuesday walks to lunch — readings evened out by May 28."),
            visual: .chart("bp"),
            sources: ["Sleep duration via HealthKit (4 weeks)", "Home BP readings (4 weeks)", "Work rhythm you told me about in April"]
        ),
    ]

    // MARK: Today's Thread (Day-state: established user)

    static func moments(insights: [Insight]) -> [Moment] {
        [
            Moment(
                kind: .insight,
                title: "Steadiest week in a month",
                body: "Your BP readings this week are the calmest run since early May. Worth seeing.",
                actionLabel: "Show me",
                insightID: insights.first?.id
            ),
            Moment(
                kind: .habit,
                title: "Your walk window is open",
                body: "Braves don't play tonight — the 15 minutes after dinner is all yours.",
                actionLabel: "I'm on it"
            ),
            Moment(
                kind: .task,
                title: "Atorvastatin — Thursday",
                body: "You'll run out next Thursday. The refill is ready at CVS Peachtree.",
                actionLabel: "Make it ready",
                medID: "atorvastatin"
            ),
        ]
    }

    // MARK: Journeys

    static let journeys: [Journey] = [
        Journey(
            title: "Evenings that move",
            why: "Fifteen minutes after dinner — for the BP, and for DeShawn seeing you do it.",
            habits: [
                AtomicHabit(
                    title: "15-minute walk after dinner",
                    contextLine: "after the Braves game ends — or 7:30 on quiet nights",
                    keptDates: (1...14).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: .now) }.enumerated().compactMap { index, day in index % 3 == 0 ? nil : day }
                )
            ],
            gardenSeed: 42
        ),
        Journey(
            title: "Steady mornings",
            why: "Meds with breakfast, every day — boring on purpose. Boring is winning.",
            habits: [
                AtomicHabit(
                    title: "Metformin + lisinopril with breakfast",
                    contextLine: "right after the first coffee",
                    keptDates: (1...20).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: .now) }.enumerated().compactMap { index, day in index % 7 == 6 ? nil : day }
                )
            ],
            gardenSeed: 7
        ),
    ]

    // MARK: Programs
    // GOVERNANCE LAW (restated at the ranking site, §3.14): sponsorship can never
    // alter clinical eligibility, ranking among clinically-equivalent options, or
    // the companion's language about alternatives. Programs are ordered by
    // clinical relevance only. The sponsored experience differs ONLY by the
    // disclosure chip.

    static let programs: [Program] = [
        Program(
            title: "Kidney-smart eating, made livable",
            summary: "Four weeks of small swaps that protect your kidneys without turning dinner into homework.",
            sponsor: "Meridian Therapeutics",
            sponsorDetail: "Meridian funds the dietitian content and your access — free to you. They receive program-level enrollment numbers, never your name or your records. Sponsorship never changes what we recommend; this program is here because your kidney function makes it clinically right for you.",
            clinicalWhy: "With CKD stage 2, the ADA and KDIGO guidance both point at sodium and protein balance as the highest-leverage food moves.",
            personalFit: "Built around real-life eating — including game-day food. No weighing, no logging meals.",
            provenance: "KDIGO 2024 · ADA Standards of Care",
            patientDividend: "Free dietitian content — would run about $120 elsewhere."
        ),
        Program(
            title: "Home BP, mastered in two weeks",
            summary: "Get readings your care team actually trusts — timing, posture, and what to ignore.",
            sponsor: nil,
            sponsorDetail: nil,
            clinicalWhy: "AHA guidance: home readings beat office readings for steering treatment — when they're taken right.",
            personalFit: "Two minutes a morning, built around your existing cuff.",
            provenance: "AHA home monitoring guidance",
            patientDividend: nil
        ),
    ]

    // MARK: Currents daily set

    static let currents: [CurrentsPiece] = [
        CurrentsPiece(
            format: .glance,
            kicker: "For your kidneys",
            headline: "Why your kidneys love lisinopril",
            body: "It lowers the pressure inside the kidney's tiny filters — not just in your arm. That's why Dr. Patterson calls it protective, not just a BP pill.",
            sceneSeed: 3,
            imageName: "currents_kidney",
            aiGenerated: true,
            intent: "med-understanding · lisinopril adherence"
        ),
        CurrentsPiece(
            format: .read,
            kicker: "The evening walk",
            headline: "Fifteen minutes that outwork an hour",
            body: "The walk after dinner does something the gym can't: it meets your blood sugar exactly when it peaks.\n\nMuscles pull glucose straight from the blood for about ninety minutes after you eat. A walk in that window is like opening a second drain — no willpower contest, no gear, no good weather required.\n\nFor blood pressure it's quieter still: the rhythm of unhurried walking nudges vessels to relax for hours afterward. Your steadiest BP weeks this spring have all been walking weeks. That's not a coincidence; that's a pattern with receipts.\n\nThe trick that makes it stick isn't discipline. It's placement. Not \"walk more\" — walk after dinner, when the game's over and the kitchen's closed. Same shoes by the door. Same loop. Let it be boring. Boring is what habits are made of.",
            sceneSeed: 9,
            imageName: "currents_walk",
            aiGenerated: true,
            intent: "journey-support · evening walks"
        ),
        CurrentsPiece(
            format: .watch,
            kicker: "Your numbers, decoded",
            headline: "What an A1c of 8.4 actually means",
            body: "Ninety seconds on what the number measures, why direction beats position, and what \"under 8 by fall\" would take. Captioned.",
            sceneSeed: 5,
            imageName: "currents_a1c",
            aiGenerated: false,
            intent: "lab-understanding · A1c trend"
        ),
        CurrentsPiece(
            format: .listen,
            kicker: "Two minutes, spoken",
            headline: "A father, a son, and a walk",
            body: "A short listen about what it means when your kid starts lacing up to come with you. Sometimes the health part is the smallest part.",
            sceneSeed: 14,
            imageName: "currents_father_son",
            aiGenerated: true,
            intent: "relational · walking journey wobble-guard"
        ),
        CurrentsPiece(
            format: .glance,
            kicker: "Small swap",
            headline: "The salt that hides in Sunday",
            body: "One deli sandwich can carry more sodium than three home dinners. The swap isn't \"no sandwich\" — it's half the meat, double the tomato, same sandwich.",
            sceneSeed: 21,
            imageName: "currents_salt",
            aiGenerated: true,
            intent: "kidney-smart eating · pre-program warm-up"
        ),
        CurrentsPiece(
            format: .read,
            kicker: "The morning number",
            headline: "Why your BP is highest before you've done a thing",
            body: "Blood pressure has a daily tide. It climbs in the hour before you wake — your body bracing for the day — and that surge is exactly why morning readings matter most.\n\nIt isn't stress and it isn't coffee. It's a built-in rhythm called the morning surge, and for kidneys it's the window that does the most wear. That's the real reason lisinopril is a morning pill: it's there to meet the surge head-on.\n\nSo when you take a reading after breakfast and it reads a little high, don't take it as a verdict. Take it as information arriving right on schedule. What we watch is the week, not the morning.",
            sceneSeed: 33,
            imageName: nil,
            aiGenerated: true,
            intent: "lab-understanding · BP literacy"
        ),
        CurrentsPiece(
            format: .glance,
            kicker: "One small win",
            headline: "Water is a kidney's best friend",
            body: "On warehouse shift days, a refilled bottle by the forklift does quiet, real work — steadier filtering, easier numbers. Not a gallon. Just don't run dry.",
            sceneSeed: 38,
            imageName: nil,
            aiGenerated: true,
            intent: "kidney-smart · hydration habit"
        ),
        CurrentsPiece(
            format: .watch,
            kicker: "Two minutes",
            headline: "What metformin actually does, drawn simply",
            body: "A short, calm animation: your liver quietly over-pours sugar overnight, and how metformin turns the tap down. No jargon, captioned, skip-anytime.",
            sceneSeed: 41,
            imageName: nil,
            aiGenerated: true,
            intent: "med-understanding · metformin adherence"
        ),
        CurrentsPiece(
            format: .listen,
            kicker: "Three minutes, spoken",
            headline: "The myth of the perfect diabetes diet",
            body: "There isn't one. There's the plate you'll actually eat on a Tuesday. A short listen on why \"good enough, most days\" beats \"perfect, until you quit.\"",
            sceneSeed: 46,
            imageName: nil,
            aiGenerated: true,
            intent: "food-relationship · shame-reduction"
        ),
        CurrentsPiece(
            format: .read,
            kicker: "For the long game",
            headline: "Direction beats the number, every time",
            body: "An 8.4 that came down from 9.4 is a different story than an 8.4 climbing from 7.8 — even though the number is identical.\n\nDoctors read trends because the body responds to momentum. Five drops in a row tells us the plan is working and your body is answering. One number can't say that. A line can.\n\nThis is also why we don't chase a single bad reading with panic. We ask: which way is the line pointing, and for how long? Yours has pointed the right way for a year. Keep feeding the line.",
            sceneSeed: 5,
            imageName: "currents_a1c",
            aiGenerated: true,
            intent: "lab-understanding · A1c motivation"
        ),
        CurrentsPiece(
            format: .glance,
            kicker: "Game-day food",
            headline: "Wings, without the regret spiral",
            body: "You can have the wings. Pair them with a glass of water first and a walk after the ninth inning — the blood sugar barely notices, and you didn't miss the game.",
            sceneSeed: 52,
            imageName: nil,
            aiGenerated: true,
            intent: "livable-eating · Braves nights"
        ),
        CurrentsPiece(
            format: .listen,
            kicker: "Two minutes, spoken",
            headline: "Showing up tired still counts",
            body: "On the days the night shift wins, the walk gets shorter — not skipped. A short listen on why a five-minute version of a habit protects the streak that matters.",
            sceneSeed: 57,
            imageName: nil,
            aiGenerated: true,
            intent: "habit-resilience · shift weeks"
        ),
        CurrentsPiece(
            format: .read,
            kicker: "Quietly important",
            headline: "The pharmacy trick that ends refill panic",
            body: "Running out on a Thursday isn't a discipline problem. It's a calendar problem — three prescriptions, three different clocks.\n\nThe fix is boring and it works: sync them. Most pharmacies will line up all your fills to the same date for free, so it becomes one trip, one reminder, one thing to remember instead of three.\n\nAsk for \"med synchronization\" at CVS Peachtree. Or say the word and I'll tee it up — the next time you pick up should be the last time three bottles ran out on different days.",
            sceneSeed: 61,
            imageName: nil,
            aiGenerated: true,
            intent: "adherence · refill-sync"
        ),
        CurrentsPiece(
            format: .glance,
            kicker: "For DeShawn",
            headline: "The habit your kid is actually watching",
            body: "Kids rarely do what we say. They do what they see at 7:30 on a quiet night. The after-dinner walk is teaching something long after the BP reading is forgotten.",
            sceneSeed: 14,
            imageName: "currents_father_son",
            aiGenerated: true,
            intent: "relational · legacy motivation"
        ),
        CurrentsPiece(
            format: .watch,
            kicker: "60 seconds",
            headline: "How a walk lowers blood sugar, visualized",
            body: "Watch glucose leave the bloodstream and feed working muscle in real time. The clearest minute you'll spend on why the timing of a walk matters more than the distance.",
            sceneSeed: 9,
            imageName: "currents_walk",
            aiGenerated: false,
            intent: "journey-support · walk mechanism"
        ),
        CurrentsPiece(
            format: .read,
            kicker: "Kidney-smart",
            headline: "Potassium isn't the enemy — runaway potassium is",
            body: "With stage-2 kidneys and lisinopril on board, potassium is worth knowing, not fearing.\n\nMost foods are fine in normal portions. The traps are the concentrated ones — salt substitutes (often pure potassium), big daily orange juice, handfuls of dried fruit. It's the dose that matters, not the food.\n\nYour March panel read 4.4, comfortably normal. We keep an eye on it with your regular labs, and if a number ever drifts I'll tell you plainly and we'll adjust — no guesswork, no scary internet lists.",
            sceneSeed: 3,
            imageName: "currents_kidney",
            aiGenerated: true,
            intent: "kidney-smart eating · potassium literacy"
        ),
        CurrentsPiece(
            format: .glance,
            kicker: "Sleep & numbers",
            headline: "A short night writes itself into tomorrow's cuff",
            body: "On weeks with night shifts, your morning BP runs 6–8 points higher the day after. Not a failing — a pattern. Worth a lighter Tuesday, not a guilt trip.",
            sceneSeed: 67,
            imageName: nil,
            aiGenerated: true,
            intent: "pattern-awareness · sleep-BP link"
        ),
        CurrentsPiece(
            format: .listen,
            kicker: "Three minutes, spoken",
            headline: "Carrying a diagnosis like a man, redefined",
            body: "A short, honest listen on why asking for the refill, the reminder, the help — isn't weakness. It's the same strength that shows up for everyone else, finally pointed at yourself.",
            sceneSeed: 72,
            imageName: nil,
            aiGenerated: true,
            intent: "emotional · self-care permission"
        ),
        CurrentsPiece(
            format: .read,
            kicker: "At the next visit",
            headline: "The three questions that make a 12-minute appointment count",
            body: "Visits are short. The patients who leave with a real plan tend to bring three things, not twenty.\n\nOne: the trend that's been on your mind — your A1c slide, your steadiest BP week. Two: the one symptom worth a name — the leg cramps on late-statin nights. Three: the logistics question — \"can we sync my refills?\"\n\nI can have all three on a single page before June 24, in the order Dr. Patterson reads fastest. You walk in ready; you walk out with answers instead of a follow-up.",
            sceneSeed: 78,
            imageName: nil,
            aiGenerated: true,
            intent: "visit-prep · agenda-building"
        ),
        CurrentsPiece(
            format: .glance,
            kicker: "Small swap",
            headline: "The breakfast that holds your morning steady",
            body: "Trade the sweet cereal for oats and berries one day this week. Same bowl, same five minutes — but the blood sugar curve goes from a spike to a gentle hill.",
            sceneSeed: 84,
            imageName: nil,
            aiGenerated: true,
            intent: "livable-eating · breakfast swap"
        ),
        CurrentsPiece(
            format: .watch,
            kicker: "90 seconds",
            headline: "Statins and your muscles — the real story",
            body: "A calm explainer on why some people feel cramps on a statin, what's worth telling me about, and why — with your numbers — the heart math still comes out strongly in favor. Captioned.",
            sceneSeed: 89,
            imageName: nil,
            aiGenerated: false,
            intent: "med-understanding · atorvastatin reassurance"
        ),
        CurrentsPiece(
            format: .read,
            kicker: "The quiet science",
            headline: "Why boring is the most underrated word in medicine",
            body: "The flashiest health advice changes every year. The stuff that actually moved your numbers is almost embarrassingly dull: the same pills, with the same breakfast, and a walk on most nights.\n\nThat's not a consolation prize. Consistency compounds — a medication taken 9 days in 10 protects you in a way a perfect day once a month never can. Your kidneys, your heart, your morning numbers all run on repetition, not intensity.\n\nSo when a week feels unremarkable, read it the way I do: that's a winning week. Boring is the sound of a plan working.",
            sceneSeed: 95,
            imageName: nil,
            aiGenerated: true,
            intent: "motivation · consistency reframe"
        ),
        CurrentsPiece(
            format: .glance,
            kicker: "Money & meds",
            headline: "You might be overpaying for the exact same pill",
            body: "Generic atorvastatin can swing a lot in price across pharmacies and discount cards. Same molecule, smaller number. Want me to check what your three would cost a few blocks over?",
            sceneSeed: 101,
            imageName: nil,
            aiGenerated: true,
            intent: "affordability · cost-of-care"
        ),
        CurrentsPiece(
            format: .listen,
            kicker: "Two minutes, spoken",
            headline: "The walk that became a conversation",
            body: "A short listen on how the fifteen minutes after dinner turned into the part of the day a father and son actually talk. Sometimes the health is the side effect.",
            sceneSeed: 14,
            imageName: "currents_father_son",
            aiGenerated: true,
            intent: "relational · journey reinforcement"
        ),
        CurrentsPiece(
            format: .read,
            kicker: "Worth the read",
            headline: "What stage-2 kidneys really mean — and don't",
            body: "\"Kidney disease\" lands heavy. Stage 2 deserves a steadier read.\n\nIt means your filtering is mildly reduced and, just as importantly, holding steady — yours has barely moved in two years. The job now isn't repair; it's protection: steady BP, the kidney-friendly dose of lisinopril, easy on ibuprofen, decent hydration.\n\nDone consistently, many people hold stage 2 for decades without it ever becoming the headline of their health. That's the plan you're already living. This is the read I'd want a friend to have — clear-eyed, not catastrophized.",
            sceneSeed: 3,
            imageName: "currents_kidney",
            aiGenerated: true,
            intent: "condition-literacy · CKD reassurance"
        ),
        CurrentsPiece(
            format: .glance,
            kicker: "Tiny experiment",
            headline: "Park at the far end of the lot",
            body: "Not a workout — a default. The extra ninety steps to the warehouse door, twice a shift, add up to a mile a week you never had to schedule.",
            sceneSeed: 108,
            imageName: nil,
            aiGenerated: true,
            intent: "movement · friction-free steps"
        ),
    ]

    // MARK: Care team

    static let careTeam: [CareTeamMember] = [
        CareTeamMember(name: "Dr. Alicia Patterson", role: "Primary care", org: "Piedmont Internal Medicine · Privia"),
        CareTeamMember(name: "Dr. Samuel Okafor", role: "Nephrology", org: "Emory Healthcare"),
        CareTeamMember(name: "CVS Peachtree", role: "Pharmacy", org: "Peachtree St NE, Atlanta"),
    ]

    static let appointments: [Appointment] = [
        Appointment(with: "Dr. Alicia Patterson", date: date(2026, 6, 24), location: "Piedmont Internal Medicine", prepReady: true),
    ]

    // MARK: Sources & consent

    static let sources: [RecordSource] = [
        RecordSource(name: "Piedmont Internal Medicine", railLabel: "Privia · direct connection", connected: true, lastSync: Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now),
        RecordSource(name: "Emory Healthcare", railLabel: "MyChart · patient access", connected: true, lastSync: Calendar.current.date(byAdding: .hour, value: -14, to: .now) ?? .now),
        RecordSource(name: "CVS Pharmacy", railLabel: "Dispense records", connected: true, lastSync: Calendar.current.date(byAdding: .minute, value: -35, to: .now) ?? .now),
        RecordSource(name: "Apple Health", railLabel: "Steps, sleep, BP cuff", connected: true, lastSync: Calendar.current.date(byAdding: .minute, value: -8, to: .now) ?? .now),
    ]

    static let consents: [ConsentEntry] = [
        ConsentEntry(source: "Piedmont · Privia", scope: "Labs, medications, conditions, notes", granted: true, at: date(2026, 4, 2)),
        ConsentEntry(source: "Emory · MyChart", scope: "Labs, visit notes, procedures", granted: true, at: date(2026, 4, 2)),
        ConsentEntry(source: "CVS Pharmacy", scope: "Dispense and refill status", granted: true, at: date(2026, 4, 2)),
        ConsentEntry(source: "Apple Health", scope: "Steps, sleep, heart rate, BP, weight", granted: true, at: date(2026, 4, 2)),
        ConsentEntry(source: "Consumer insights (Epsilon)", scope: "Timing, tone, and framing — never advertising", granted: true, at: date(2026, 4, 2)),
    ]

    static let memory: [MemoryItem] = [
        MemoryItem(text: "What matters most: being there for DeShawn's college years", learnedFrom: "Your first conversation"),
        MemoryItem(text: "Hardest part: night shifts wreck the routine", learnedFrom: "Your first conversation"),
        MemoryItem(text: "Prefers straight talk — with warmth", learnedFrom: "Your tone setting"),
        MemoryItem(text: "Braves fan — walk windows open after games", learnedFrom: "Conversations in April"),
        MemoryItem(text: "Mornings are chaos; evenings are yours", learnedFrom: "Pattern in your check-ins"),
    ]

}
