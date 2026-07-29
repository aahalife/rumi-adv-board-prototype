import Foundation

/// Persona fixture corpus — the same calm world, three very different lives
/// inside it. Marcus (the long metabolic game), Elena (mid-chemo), and
/// Sam (a knee replacement two weeks out). Switching personas re-shapes
/// symptoms, metrics, moments, the care plan, and the companion's watchlist.
enum PersonaFixtures {

    static func persona(for pathway: CarePathway) -> Persona {
        switch pathway {
        case .metabolic: return marcus
        case .oncology: return elena
        case .procedure: return sam
        case .cardiometabolic: return rosa
        }
    }

    // MARK: - Marcus · the long game (T2D · HTN · CKD-2)

    static let marcus = Persona(
        pathway: .metabolic,
        firstName: "Marcus",
        switcherLine: "Marcus · diabetes & blood pressure · the long game",
        conditions: [
            CareCondition(
                name: "Type 2 diabetes", since: "2019", state: "actively managed",
                plainLine: "Your A1c has moved down five readings in a row. The walks and steady metformin are why.",
                glyph: "drop", accent: .gold
            ),
            CareCondition(
                name: "High blood pressure", since: "2017", state: "trending calmer",
                plainLine: "This week was your steadiest in a month — evenings are doing quiet work here.",
                glyph: "heart", accent: .warm
            ),
            CareCondition(
                name: "Kidneys, stage 2", since: "2024", state: "holding steady",
                plainLine: "Caught early, protected since. Water on shifts, easy on ibuprofen — that's your part.",
                glyph: "leaf", accent: .life
            ),
        ],
        conditionChip: "Diabetes · BP · kidneys",
        heroImage: "condition_diabetes",
        phase: CarePhase(
            kicker: "The long game",
            headline: "Year two of turning this around",
            detail: "No finish line here — just direction. And yours has been good for five readings straight.",
            progress: nil
        ),
        expectations: [
            ExpectationItem(window: "Most days", title: "Boring is winning",
                            detail: "Meds with breakfast, a walk after dinner. The unglamorous stuff is exactly what's moving your numbers.", accent: .life),
            ExpectationItem(window: "Night-shift weeks", title: "Numbers drift — that's the schedule, not you",
                            detail: "Short nights show up in next-morning readings. We plan around shift weeks instead of fighting them.", accent: .sky),
            ExpectationItem(window: "Every ~3 months", title: "Lab day",
                            detail: "A1c, kidney panel, cholesterol. I'll have the trends charted before you sit down with Dr. Patterson.", accent: .gold),
        ],
        carePlan: CarePlan(
            author: "Dr. Alicia Patterson",
            updated: "March 12, 2026",
            intro: "\u{201C}Real progress. Keep the walking.\u{201D} — the plan, in her words and yours:",
            goals: [
                CarePlanGoal(title: "A1c under 8 by fall", detail: "Steady metformin, evening movement, no crash diets.",
                             progressLine: "On its way — 8.4 and falling", accent: .gold),
                CarePlanGoal(title: "Home BP in the calm zone", detail: "Readings most mornings; lisinopril with breakfast.",
                             progressLine: "Steadiest week in a month", accent: .warm),
                CarePlanGoal(title: "Protect the kidneys", detail: "Hydrate on shifts, skip routine ibuprofen, kidney panel each visit.",
                             progressLine: "Holding at stage 2 — stable", accent: .life),
                CarePlanGoal(title: "Move after dinner", detail: "15 minutes, most evenings. The Braves schedule is a planning tool now.",
                             progressLine: "11 of the last 14 evenings", accent: .sky),
            ]
        ),
        symptomKinds: [
            SymptomKind("Leg cramps", glyph: "figure.walk", needsBodyMap: true),
            SymptomKind("Dizziness", glyph: "wind"),
            SymptomKind("Headache", glyph: "brain.head.profile", needsBodyMap: true),
            SymptomKind("Low energy", glyph: "battery.25"),
            SymptomKind("Foot tingling", glyph: "shoeprints.fill", needsBodyMap: true),
            SymptomKind("Stress", glyph: "tornado"),
            SymptomKind("Poor sleep", glyph: "moon.zzz"),
            SymptomKind("Swelling", glyph: "drop.circle", needsBodyMap: true),
        ],
        labSeries: MarcusFixtures.labSeries,
        medications: MarcusFixtures.medications,
        careTeam: MarcusFixtures.careTeam,
        officePhone: "404-555-0142",
        officeName: "Dr. Patterson's office",
        appointments: MarcusFixtures.appointments,
        journeys: MarcusFixtures.journeys,
        insights: MarcusFixtures.insights,
        storyEvents: MarcusFixtures.storyEvents,
        currents: MarcusFixtures.currents,
        moments: MarcusFixtures.moments(insights: MarcusFixtures.insights),
        statusQuiet: "All quiet. Exactly how we like it.",
        statusBusy: "A few things worth your time — no rush.",
        guideSeed: [
            GuideItem(kind: .question, text: "Leg cramps cluster on late-statin days — worth a timing tweak?",
                      addedFrom: "From the pattern we caught · May 26"),
            GuideItem(kind: .observation, text: "Steadiest BP week in a month — evening walks are landing.",
                      addedFrom: "From your home cuff · this week"),
        ]
    )

    // MARK: - Elena · mid-chemo (breast cancer · AC-T · cycle 3 of 6)

    static let elena = Persona(
        pathway: .oncology,
        firstName: "Elena",
        switcherLine: "Elena · breast cancer · chemo cycle 3 of 6",
        conditions: [
            CareCondition(
                name: "Breast cancer", since: "January 2026", state: "in treatment — responding",
                plainLine: "Cycle 3 of 6. Dr. Rivera called the last scan \u{201C}exactly what we hoped to see.\u{201D}",
                glyph: "sparkles", accent: .rose
            ),
            CareCondition(
                name: "Chemotherapy course", since: "February 2026", state: "AC-T · cycle 3 of 6",
                plainLine: "Halfway through the harder half. Your body is keeping remarkable rhythm with it.",
                glyph: "calendar", accent: .sky
            ),
        ],
        conditionChip: "Breast cancer · cycle 3 of 6",
        heroImage: "condition_chemo",
        phase: CarePhase(
            kicker: "Chemotherapy · cycle 3 of 6",
            headline: "Day 6 — the turn toward better days",
            detail: "The queasy window is behind you. Counts dip around day 7–10, so it's gentle-with-yourself week: small crowds, good handwashing, naps without guilt.",
            progress: 3.0 / 6.0
        ),
        expectations: [
            ExpectationItem(window: "Days 1–3", title: "The queasy window",
                            detail: "Nausea peaks here. Ondansetron works best on schedule, not heroically after the fact. Cold food smells less.", accent: .sky),
            ExpectationItem(window: "Days 4–7", title: "Tired, but turning",
                            detail: "Heavy-limbed days. Rest is treatment too — and a 10-minute walk on the better days genuinely helps the fatigue.", accent: .gold),
            ExpectationItem(window: "Days 7–10", title: "Counts at their lowest",
                            detail: "Your immune guard is briefly down. A fever of 100.4°F or higher is a call-the-team-now moment — any hour, no hesitating.", accent: .warm),
            ExpectationItem(window: "Days 10–21", title: "The good window",
                            detail: "Energy comes back. This is the window for the things that make you feel like you — plan them here.", accent: .life),
        ],
        carePlan: CarePlan(
            author: "Dr. Maya Rivera",
            updated: "June 4, 2026",
            intro: "The plan for cycles 3 and 4 — protection first, life where it fits:",
            goals: [
                CarePlanGoal(title: "Stay ahead of nausea", detail: "Ondansetron on schedule days 1–3, not as a rescue.",
                             progressLine: "Cycle 3 was your smoothest yet", accent: .sky),
                CarePlanGoal(title: "Fever rule — 100.4°F means call", detail: "Any time, day or night. The on-call line always answers.",
                             progressLine: nil, accent: .warm),
                CarePlanGoal(title: "Hydration through infusion week", detail: "Eight glasses on infusion days; it eases almost everything.",
                             progressLine: "You kept it 5 of 7 days last cycle", accent: .gold),
                CarePlanGoal(title: "Move on the good days", detail: "Short walks when energy allows — fatigue's best medicine, oddly.",
                             progressLine: "Three gentle walks last window", accent: .life),
            ]
        ),
        symptomKinds: [
            SymptomKind("Nausea", glyph: "wind"),
            SymptomKind("Fatigue", glyph: "battery.25"),
            SymptomKind("Fever or chills", glyph: "thermometer.medium"),
            SymptomKind("Mouth sores", glyph: "mouth"),
            SymptomKind("Tingling hands/feet", glyph: "hand.raised", needsBodyMap: true),
            SymptomKind("Appetite", glyph: "fork.knife"),
            SymptomKind("Worry", glyph: "cloud"),
            SymptomKind("Poor sleep", glyph: "moon.zzz"),
        ],
        labSeries: [
            LabSeries(
                id: "anc", name: "Immune guard (ANC)", unit: "k/µL",
                points: [
                    LabPoint(date: MarcusFixtures.date(2026, 4, 20), value: 1.8),
                    LabPoint(date: MarcusFixtures.date(2026, 5, 4), value: 1.1),
                    LabPoint(date: MarcusFixtures.date(2026, 5, 18), value: 1.9),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 1), value: 1.2),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 8), value: 1.7),
                ],
                band: 1.5...8.0, bandLabel: "comfortable range",
                annotation: SeriesAnnotation(date: MarcusFixtures.date(2026, 6, 1), label: "cycle 3 infusion"),
                provenance: "From your Jun 8 Northside lab",
                explainReading: "ANC counts the white cells that fight infection. Yours dips after each infusion and recovers before the next — exactly the rhythm your team plans around.",
                explainNextStep: "During the dip (days 7–10), it's small-crowds-and-handwashing week. Recovery has been reliable every cycle.",
                explainAsk: "Want a gentle heads-up when you enter the low-count window each cycle?"
            ),
            LabSeries(
                id: "weight", name: "Weight", unit: "lb",
                points: [
                    LabPoint(date: MarcusFixtures.date(2026, 4, 6), value: 148),
                    LabPoint(date: MarcusFixtures.date(2026, 4, 27), value: 146),
                    LabPoint(date: MarcusFixtures.date(2026, 5, 18), value: 145),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 8), value: 145),
                ],
                band: 140...155, bandLabel: "your steady zone",
                annotation: nil,
                provenance: "From your infusion-day check-ins",
                explainReading: "Holding steady through chemo is genuinely hard to do — and you're doing it. Three pounds over two months is the gentle kind of change.",
                explainNextStep: "Keep the small frequent meals. If a week drops more than 2–3 pounds, that's worth telling the team — food is part of treatment.",
                explainAsk: "Want me to put weight on your visit-prep for Dr. Rivera?"
            ),
        ],
        medications: [
            Medication(
                id: "ondansetron", name: "Ondansetron", dose: "8 mg · as scheduled",
                purposeLine: "keeps nausea ahead of you, not behind",
                scheduleLine: "days 1–3 after infusion, every 8 hours",
                supplyDaysRemaining: 14, pharmacy: "Northside Pharmacy",
                guidance: ["Works best on schedule, not as a rescue after nausea starts", "Constipation is its known quirk — water and movement help"],
                watchlist: ["If nausea breaks through on schedule, the team has stronger options — say so", "Headache is common and mild"],
                history: ["8 mg scheduled — since cycle 1 (February 2026)"],
                adherence30: [1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1]
            ),
            Medication(
                id: "dexamethasone", name: "Dexamethasone", dose: "4 mg · infusion days",
                purposeLine: "softens the infusion's edges",
                scheduleLine: "morning of infusion + 2 days after, with food",
                supplyDaysRemaining: 20, pharmacy: "Northside Pharmacy",
                guidance: ["Take it with breakfast — it can make sleep lively if taken late", "Some people feel wired then dip — that's the medicine, not you"],
                watchlist: ["Mood swings on dexamethasone days are real and temporary", "Mention persistent hiccups — there's a fix"],
                history: ["4 mg around infusions — since cycle 1"],
                adherence30: [1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1]
            ),
        ],
        careTeam: [
            CareTeamMember(name: "Dr. Maya Rivera", role: "Oncology", org: "Northside Cancer Institute"),
            CareTeamMember(name: "Nia Coleman, RN", role: "Infusion nurse navigator", org: "Northside Cancer Institute"),
            CareTeamMember(name: "Northside Pharmacy", role: "Pharmacy", org: "Peachtree Dunwoody Rd"),
        ],
        officePhone: "404-555-0188",
        officeName: "Dr. Rivera's team",
        appointments: [
            Appointment(with: "Cycle 4 infusion · Dr. Rivera's team", date: MarcusFixtures.date(2026, 6, 22), location: "Northside Infusion Center", prepReady: true),
            Appointment(with: "Dr. Maya Rivera", date: MarcusFixtures.date(2026, 7, 6), location: "Northside Cancer Institute", prepReady: false),
        ],
        journeys: [
            Journey(
                title: "Good-day movement",
                why: "Ten gentle minutes on the days that allow it — fatigue's strangest, best medicine.",
                habits: [
                    AtomicHabit(
                        title: "10-minute walk on good days",
                        contextLine: "days 10–21 of each cycle — your window",
                        keptDates: (1...10).compactMap { Calendar.current.date(byAdding: .day, value: -$0 * 2, to: .now) }
                    )
                ],
                gardenSeed: 11
            ),
            Journey(
                title: "Infusion week, watered",
                why: "Eight glasses on infusion days. It eases the nausea, the fatigue, almost everything.",
                habits: [
                    AtomicHabit(
                        title: "Water bottle finished twice",
                        contextLine: "infusion day + 3 days after",
                        keptDates: (1...8).compactMap { Calendar.current.date(byAdding: .day, value: -$0 * 3, to: .now) }
                    )
                ],
                gardenSeed: 23
            ),
        ],
        insights: [
            Insight(
                category: .pattern,
                headline: "Your nausea peaks on day 2 — and your schedule can meet it",
                body: "Across three cycles, the hardest hours land the evening of day 2. Taking ondansetron on schedule that morning — not waiting — has made each cycle smoother than the last.",
                confidence: "Based on 3 cycles of logs — a steady rhythm, not a guess.",
                provenance: "Your logs · infusion dates from Northside",
                actionLabel: "Set the day-2 reminder",
                status: .fresh,
                visual: .scene(31),
                sources: ["Symptom logs: nausea (9 entries)", "Infusion schedule (3 cycles)", "Ondansetron dose times"]
            ),
            Insight(
                category: .milestone,
                headline: "Halfway. Say it out loud.",
                body: "Three cycles done, three to go. Your counts have recovered on time every single cycle, and the last scan read the way everyone hoped. This is what getting through looks like.",
                confidence: nil,
                provenance: "Northside labs · 3 cycles",
                actionLabel: "See the journey so far",
                status: .fresh,
                visual: .scene(8),
                sources: ["ANC recovery curve (3 cycles)", "Dr. Rivera's May scan note"]
            ),
        ],
        storyEvents: [
            StoryEvent(kind: .milestone, date: MarcusFixtures.date(2026, 6, 8), title: "Counts recovered — right on time", detail: "Third cycle in a row. Your body keeps its promises."),
            StoryEvent(kind: .visit, date: MarcusFixtures.date(2026, 6, 1), title: "Cycle 3 infusion", detail: "Smoothest one yet — the scheduled anti-nausea plan worked."),
            StoryEvent(kind: .result, date: MarcusFixtures.date(2026, 5, 12), title: "Scan: \u{201C}exactly what we hoped\u{201D}", detail: "Dr. Rivera's words. The treatment is doing its job."),
            StoryEvent(kind: .milestone, date: MarcusFixtures.date(2026, 4, 20), title: "Cycle 2 — you found the rhythm", detail: "Queasy window, tired turn, good days. Named, mapped, survivable."),
            StoryEvent(kind: .visit, date: MarcusFixtures.date(2026, 2, 16), title: "Cycle 1 — the hardest first", detail: "You walked in scared and walked out started. That counts double."),
            StoryEvent(kind: .diagnosis, date: MarcusFixtures.date(2026, 1, 22), title: "Diagnosis", detail: "The day the story changed. Not the day it ended — the day this chapter began."),
        ],
        currents: [
            CurrentsPiece(
                format: .glance, kicker: "For the queasy window",
                headline: "Cold plates, quiet smells",
                body: "Nausea hates cold food — less aroma, less trouble. Chilled fruit, yogurt, rice at room temperature. The microwave is not your friend on days 1–3.",
                sceneSeed: 4, imageName: "currents_salt", aiGenerated: true,
                intent: "cycle-support · nausea management"
            ),
            CurrentsPiece(
                format: .read, kicker: "The good window",
                headline: "Days 10 to 21 belong to you",
                body: "Every cycle has a window where the fog lifts and energy returns. Yours has opened on day 10, reliably, three cycles running.\n\nThe trick is planning for it. Not the laundry — the living. The friend you keep postponing, the garden, the drive with the windows down. Treatment takes the days it takes; the window is how you take some back.\n\nFatigue research says the strangest thing: gentle movement during the good window stretches it. Ten minutes of walking, most good days, and the next dip tends to land softer.",
                sceneSeed: 9, imageName: "currents_walk", aiGenerated: true,
                intent: "journey-support · good-day movement"
            ),
            CurrentsPiece(
                format: .listen, kicker: "Two minutes, spoken",
                headline: "What halfway feels like",
                body: "A short listen about the middle of hard things — when the start is far behind and the end is not yet near, and you keep going anyway.",
                sceneSeed: 14, imageName: "currents_father_son", aiGenerated: true,
                intent: "relational · halfway milestone"
            ),
        ],
        moments: [
            Moment(
                kind: .checkIn,
                title: "Day 6 — how's the turn?",
                body: "By tonight the heaviness usually starts lifting. Tell me where you are and I'll shape the week around it.",
                actionLabel: "Check in"
            ),
            Moment(
                kind: .task,
                title: "Low-count window opens tomorrow",
                body: "Days 7–10: small crowds, good handwashing, and the fever rule on the fridge. I'll keep watch with you.",
                actionLabel: "What to watch"
            ),
            Moment(
                kind: .habit,
                title: "Water counts double this week",
                body: "Infusion week hydration is still working through your system — one more good day of it.",
                actionLabel: "Done today"
            ),
        ],
        statusQuiet: "A quiet day in cycle 3. Take it.",
        statusBusy: "Cycle 3, day 6 — here's what matters today.",
        guideSeed: [
            GuideItem(kind: .question, text: "Tingling in my fingertips since cycle 2 — is this the neuropathy to watch?",
                      addedFrom: "From your logs · May 30"),
            GuideItem(kind: .question, text: "Can we plan cycle 4's anti-nausea schedule the same as cycle 3?",
                      addedFrom: "Added after cycle 3 went smoothly"),
            GuideItem(kind: .observation, text: "Smoothest infusion week yet — scheduled ondansetron made the difference.",
                      addedFrom: "From your cycle 3 logs"),
        ]
    )

    // MARK: - Sam · knee replacement in 12 days (procedure)

    static let sam = Persona(
        pathway: .procedure,
        firstName: "Sam",
        switcherLine: "Sam · knee replacement · 12 days out",
        conditions: [
            CareCondition(
                name: "Right knee osteoarthritis", since: "2021", state: "surgery scheduled · June 23",
                plainLine: "Replacement day is June 23. The next twelve days are about walking in strong.",
                glyph: "figure.walk", accent: .sky
            ),
        ],
        conditionChip: "Knee replacement · June 23",
        heroImage: "condition_procedure",
        phase: CarePhase(
            kicker: "Procedure ahead · 12 days",
            headline: "Getting you strong for June 23",
            detail: "Prehab now pays off twice after — people who walk in stronger walk out sooner. The countdown checklist is short and all of it matters.",
            progress: 0.6
        ),
        expectations: [
            ExpectationItem(window: "Now → day −7", title: "Prehab window",
                            detail: "Quad sets and short walks daily. Stop ibuprofen and similar by June 16 — Dr. Chen's hard rule.", accent: .life),
            ExpectationItem(window: "The night before", title: "Quiet logistics",
                            detail: "Nothing to eat after midnight. Bag packed, ride confirmed, the recovery corner at home set up — ice, pillows, chargers.", accent: .gold),
            ExpectationItem(window: "Day of", title: "It's a half-day, mostly waiting",
                            detail: "Surgery itself runs about two hours. Most people are standing — carefully, triumphantly — the same day.", accent: .sky),
            ExpectationItem(window: "Weeks 1–2 after", title: "Swelling is normal; clots are the watch-item",
                            detail: "Ice and elevate daily. Calf pain, one-sided swelling, or shortness of breath is a call-now moment, not a wait-and-see.", accent: .warm),
            ExpectationItem(window: "Weeks 2–6", title: "PT is the whole game",
                            detail: "The new knee becomes yours in physical therapy. Bend by bend. It's work, and it works.", accent: .rose),
        ],
        carePlan: CarePlan(
            author: "Dr. Daniel Chen",
            updated: "June 2, 2026",
            intro: "The countdown plan — short list, every item load-bearing:",
            goals: [
                CarePlanGoal(title: "Prehab daily", detail: "Quad sets ×20 and a short walk, every day until surgery.",
                             progressLine: "9 of the last 10 days — strong", accent: .life),
                CarePlanGoal(title: "Stop NSAIDs by June 16", detail: "Ibuprofen, naproxen and friends — they thin blood around surgery.",
                             progressLine: "Reminder set for June 15", accent: .warm),
                CarePlanGoal(title: "Home, ready for after", detail: "Clear the walkways, ice packs in the freezer, raised seat installed.",
                             progressLine: "2 of 3 done", accent: .gold),
                CarePlanGoal(title: "Ride + first PT booked", detail: "Someone to drive you home; PT starts within a week after.",
                             progressLine: "Ride confirmed — PT pending", accent: .sky),
            ]
        ),
        symptomKinds: [
            SymptomKind("Knee pain", glyph: "bolt", needsBodyMap: true),
            SymptomKind("Swelling", glyph: "drop.circle", needsBodyMap: true),
            SymptomKind("Stiffness", glyph: "tortoise", needsBodyMap: true),
            SymptomKind("Poor sleep", glyph: "moon.zzz"),
            SymptomKind("Worry", glyph: "cloud"),
            SymptomKind("Low energy", glyph: "battery.25"),
        ],
        labSeries: [
            LabSeries(
                id: "pain", name: "Knee pain, evenings", unit: "/10",
                points: [
                    LabPoint(date: MarcusFixtures.date(2026, 6, 4), value: 6),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 5), value: 5),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 6), value: 6),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 7), value: 4),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 8), value: 5),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 9), value: 4),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 10), value: 4),
                ],
                band: 0...3, bandLabel: "where the new knee will live",
                annotation: nil,
                provenance: "From your evening check-ins",
                explainReading: "Evening pain has drifted from 6s to 4s since prehab started. Stronger muscles are already splinting the joint — a preview of what PT does after.",
                explainNextStep: "Keep the quad sets daily. Ice after walks if it grumbles.",
                explainAsk: "Want this trend on Dr. Chen's pre-op summary?"
            ),
        ],
        medications: [
            Medication(
                id: "acetaminophen", name: "Acetaminophen", dose: "500 mg · as needed",
                purposeLine: "the pre-surgery-safe pain option",
                scheduleLine: "up to 3g daily — your green-light option",
                supplyDaysRemaining: 30, pharmacy: "Walgreens Midtown",
                guidance: ["This one is surgery-safe right up to the night before", "Cap is 3,000 mg across the whole day — track doses, not pain"],
                watchlist: ["Ibuprofen and naproxen stop June 16 — they're the ones that thin blood", "Tell the team about any supplements; some surprise people"],
                history: ["As-needed since May, replacing routine ibuprofen"],
                adherence30: [1,0,1,1,0,1,1,1,0,1,0,1,1,0,1,1,0,1,1,0,1,0,1,1,0,1,1,0,1,1]
            ),
        ],
        careTeam: [
            CareTeamMember(name: "Dr. Daniel Chen", role: "Orthopedic surgery", org: "Midtown Orthopedics"),
            CareTeamMember(name: "Priya Nair, PT", role: "Physical therapy", org: "Midtown Rehab — starts post-op"),
            CareTeamMember(name: "Walgreens Midtown", role: "Pharmacy", org: "Peachtree St"),
        ],
        officePhone: "404-555-0167",
        officeName: "Dr. Chen's office",
        appointments: [
            Appointment(with: "Pre-op visit · Dr. Chen", date: MarcusFixtures.date(2026, 6, 17), location: "Midtown Orthopedics", prepReady: true),
            Appointment(with: "Surgery · knee replacement", date: MarcusFixtures.date(2026, 6, 23), location: "Midtown Surgical Center · arrive 6:30am", prepReady: true),
        ],
        journeys: [
            Journey(
                title: "Stronger going in",
                why: "Every quad set now is a smoother week one after. Walk in strong, walk out sooner.",
                habits: [
                    AtomicHabit(
                        title: "Quad sets ×20 + short walk",
                        contextLine: "morning coffee first, then the floor mat",
                        keptDates: (1...10).compactMap { index in index == 4 ? nil : Calendar.current.date(byAdding: .day, value: -index, to: .now) }
                    )
                ],
                gardenSeed: 33
            ),
            Journey(
                title: "Home, ready for after",
                why: "Future-you arrives on crutches. Present-you is making the house kind to them.",
                habits: [
                    AtomicHabit(
                        title: "One readiness item a day",
                        contextLine: "ice packs · walkways · shower rail · chargers by the chair",
                        keptDates: (1...6).compactMap { Calendar.current.date(byAdding: .day, value: -$0 * 2, to: .now) }
                    )
                ],
                gardenSeed: 17
            ),
        ],
        insights: [
            Insight(
                category: .pattern,
                headline: "Pain runs two points lower on prehab days",
                body: "Evenings after quad-set mornings average 4/10; skipped days run 6/10. Your muscles are already doing part of the new knee's job.",
                confidence: "Based on 10 days of evening check-ins — consistent so far.",
                provenance: "Your evening logs + habit record",
                actionLabel: "See the trend",
                status: .fresh,
                visual: .chart("pain"),
                sources: ["Evening pain logs (10 days)", "Prehab habit record"]
            ),
            Insight(
                category: .headsUp,
                headline: "NSAIDs stop in 5 days",
                body: "June 16 is the last day for ibuprofen and naproxen — they thin blood around surgery. Acetaminophen stays green-lit the whole way through.",
                confidence: nil,
                provenance: "Dr. Chen's pre-op instructions · June 2",
                actionLabel: "Set the reminder",
                status: .fresh,
                visual: .scene(19),
                sources: ["Pre-op instruction sheet (Jun 2)", "Your med list"]
            ),
        ],
        storyEvents: [
            StoryEvent(kind: .milestone, date: MarcusFixtures.date(2026, 6, 9), title: "Ten days of prehab", detail: "Nine kept. Evening pain already running lower."),
            StoryEvent(kind: .visit, date: MarcusFixtures.date(2026, 6, 2), title: "Surgery scheduled — June 23", detail: "Dr. Chen: \u{201C}You're a strong candidate. Let's get you moving again.\u{201D}"),
            StoryEvent(kind: .result, date: MarcusFixtures.date(2026, 5, 14), title: "MRI confirmed it", detail: "Bone-on-bone in the right knee. The answer to three years of grinding."),
            StoryEvent(kind: .diagnosis, date: MarcusFixtures.date(2021, 9, 8), title: "Osteoarthritis, right knee", detail: "Where the long road to June 23 started."),
        ],
        currents: [
            CurrentsPiece(
                format: .glance, kicker: "Countdown",
                headline: "What the night before looks like",
                body: "Nothing to eat after midnight. Bag by the door: ID, insurance card, loose shorts, slip-on shoes. Phone charged, ride confirmed. Then — genuinely — a movie and bed.",
                sceneSeed: 6, imageName: "condition_procedure", aiGenerated: true,
                intent: "procedure-prep · night-before"
            ),
            CurrentsPiece(
                format: .read, kicker: "Recovery, honestly",
                headline: "Week one with a new knee",
                body: "The first week is icing, elevating, and short shuffles that feel like victories — because they are.\n\nSwelling is normal and dramatic; bruising travels to strange places. What matters is the rhythm: ice after every walk, foot above heart while resting, the blood-thinner exactly on schedule.\n\nThe watch-items are few and specific: calf pain in one leg, swelling that's one-sided, fever, or shortness of breath. Those are call-now moments — everything else is the ordinary weather of healing.",
                sceneSeed: 13, imageName: "currents_a1c", aiGenerated: true,
                intent: "procedure-prep · expectation-setting"
            ),
            CurrentsPiece(
                format: .listen, kicker: "Two minutes, spoken",
                headline: "People who got their walks back",
                body: "Three short voices, one year out from the same surgery — what they'd tell the person twelve days before.",
                sceneSeed: 21, imageName: "currents_walk", aiGenerated: true,
                intent: "relational · pre-surgery confidence"
            ),
        ],
        moments: [
            Moment(
                kind: .habit,
                title: "Quad sets — day 11 of the streakless streak",
                body: "Coffee, then the mat. Each one is a smoother week one after the 23rd.",
                actionLabel: "Done"
            ),
            Moment(
                kind: .task,
                title: "Pre-op visit Tuesday",
                body: "Dr. Chen, June 17. Your prep brief is ready — the NSAID question is already on it.",
                actionLabel: "See the brief"
            ),
            Moment(
                kind: .insight,
                title: "Prehab is already paying",
                body: "Evening pain runs two points lower on exercise days. Proof the plan works.",
                actionLabel: "Show me"
            ),
        ],
        statusQuiet: "Twelve days out, right on plan.",
        statusBusy: "Twelve days to go — today's part is small and clear.",
        guideSeed: [
            GuideItem(kind: .question, text: "Which blood-thinner will I be on after, and for how long?",
                      addedFrom: "Added while reading about week one"),
            GuideItem(kind: .question, text: "When exactly do I stop the ibuprofen — morning or night of June 16?",
                      addedFrom: "From the NSAID heads-up · Jun 11"),
            GuideItem(kind: .observation, text: "Evening pain down to 4/10 on prehab days — the exercises are working.",
                      addedFrom: "From your evening check-ins"),
        ]
    )

    // MARK: - Rosa · cardiometabolic (T2D + heart failure + CKD risk, predictive)

    static let rosa = Persona(
        pathway: .cardiometabolic,
        firstName: "Rosa",
        switcherLine: "Rosa · diabetes & heart · protecting the kidneys",
        conditions: [
            CareCondition(
                name: "Type 2 diabetes", since: "2012", state: "long-managed",
                plainLine: "Fourteen years in. Empagliflozin now does double duty — steadying your sugar and shielding your heart and kidneys at once.",
                glyph: "drop", accent: .gold
            ),
            CareCondition(
                name: "Heart failure, preserved EF", since: "2024", state: "stable on treatment",
                plainLine: "Your heart pumps fine but stiffens, so fluid is the thing we watch. Your daily weigh-in is the early-warning system.",
                glyph: "heart", accent: .rose
            ),
            CareCondition(
                name: "Kidney risk — caught early", since: "flagged 2026", state: "watched closely",
                plainLine: "Rumi's risk model flagged your kidneys as the next thing to protect — not a diagnosis, a head start. The SGLT2 and the low-sodium plan are the protection.",
                glyph: "leaf", accent: .life
            ),
        ],
        conditionChip: "Diabetes · heart · kidney watch",
        heroImage: "condition_diabetes",
        phase: CarePhase(
            kicker: "Heart, sugar & kidneys",
            headline: "Protecting all three, together",
            detail: "These three pull on the same strings — so we treat them as one. The wins are quiet: a steady weight, an easy breath, numbers that hold.",
            progress: nil
        ),
        expectations: [
            ExpectationItem(window: "Every morning", title: "Weigh-in is the whole game",
                            detail: "Same time, after the bathroom, before breakfast. A 2–3 lb jump overnight is fluid — the heart's first whisper, and the easiest thing to catch early.", accent: .rose),
            ExpectationItem(window: "Most days", title: "Low-sodium, kidney-gentle",
                            detail: "Salt holds water, and water strains the heart and kidneys both. The swaps are small; the payoff shows up on the scale and the cuff.", accent: .life),
            ExpectationItem(window: "Every ~3 months", title: "The three-panel check",
                            detail: "A1c, kidney function, and a heart check. I'll have the trends charted for Dr. Shah, Dr. Reyes and Dr. Okafor before each one.", accent: .gold),
            ExpectationItem(window: "Any time", title: "Breath is a call, not a wait",
                            detail: "New shortness of breath, a fluid jump, or swelling that climbs is a same-day call to the heart team — never a wait-and-see.", accent: .warm),
        ],
        carePlan: CarePlan(
            author: "Dr. Anita Shah",
            updated: "May 28, 2026",
            intro: "\u{201C}Three conditions, one plan — and you’re steady. Keep the weigh-ins.\u{201D} — the plan, reconciled across your team:",
            goals: [
                CarePlanGoal(title: "Catch fluid early", detail: "Weigh in daily; call if you're up 3 lb overnight or 5 in a week.",
                             progressLine: "Steady within a pound for two weeks", accent: .rose),
                CarePlanGoal(title: "Protect the kidneys", detail: "Empagliflozin daily, low sodium, and an eye on eGFR each panel.",
                             progressLine: "eGFR holding — the plan's working", accent: .life),
                CarePlanGoal(title: "A1c in the steady zone", detail: "Metformin and the SGLT2; no crash diets, no skipped meals.",
                             progressLine: "7.1 and holding", accent: .gold),
                CarePlanGoal(title: "Gentle daily movement", detail: "Short walks on good-breath days — kind to the heart, never past it.",
                             progressLine: "9 of the last 14 days", accent: .sky),
            ]
        ),
        symptomKinds: [
            SymptomKind("Shortness of breath", glyph: "lungs"),
            SymptomKind("Swelling", glyph: "drop.circle", needsBodyMap: true),
            SymptomKind("Weight jump", glyph: "scalemass"),
            SymptomKind("Fatigue", glyph: "battery.25"),
            SymptomKind("Dizziness", glyph: "wind"),
            SymptomKind("Chest tightness", glyph: "heart", needsBodyMap: true),
            SymptomKind("Foot tingling", glyph: "shoeprints.fill", needsBodyMap: true),
            SymptomKind("Poor sleep", glyph: "moon.zzz"),
        ],
        labSeries: [
            LabSeries(
                id: "a1c", name: "A1c", unit: "%",
                points: [
                    LabPoint(date: MarcusFixtures.date(2025, 6, 14), value: 7.6),
                    LabPoint(date: MarcusFixtures.date(2025, 9, 20), value: 7.4),
                    LabPoint(date: MarcusFixtures.date(2025, 12, 12), value: 7.2),
                    LabPoint(date: MarcusFixtures.date(2026, 3, 14), value: 7.1),
                ],
                band: 4.5...7.0, bandLabel: "where your team wants this",
                annotation: SeriesAnnotation(date: MarcusFixtures.date(2025, 9, 20), label: "added empagliflozin"),
                provenance: "From your Mar 14 Piedmont lab",
                explainReading: "A1c is your three-month sugar average. 7.1 is close to target and steady — and the medicine holding it there is also the one guarding your heart and kidneys.",
                explainNextStep: "Nothing to change. The empagliflozin earns its keep three ways at once.",
                explainAsk: "Want this on your visit-prep for Dr. Shah?"
            ),
            LabSeries(
                id: "egfr", name: "eGFR", unit: "mL/min",
                points: [
                    LabPoint(date: MarcusFixtures.date(2025, 6, 14), value: 72),
                    LabPoint(date: MarcusFixtures.date(2025, 12, 12), value: 67),
                    LabPoint(date: MarcusFixtures.date(2026, 3, 14), value: 66),
                ],
                band: 60...90, bandLabel: "early-strain watch zone",
                annotation: SeriesAnnotation(date: MarcusFixtures.date(2025, 12, 12), label: "risk model flagged here"),
                provenance: "From your Mar 14 Emory lab",
                explainReading: "eGFR is how well your kidneys filter. 66 is mild and now holding — the dip last winter is exactly what the risk model caught early, and what the SGLT2 is protecting against.",
                explainNextStep: "Stay the course: empagliflozin daily, low sodium, easy on ibuprofen. Dr. Okafor watches this each panel.",
                explainAsk: "Want a heads-up before each kidney panel?"
            ),
            LabSeries(
                id: "weight", name: "Daily weight", unit: "lb",
                points: [
                    LabPoint(date: MarcusFixtures.date(2026, 6, 5), value: 171),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 6), value: 170),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 7), value: 171),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 8), value: 173),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 9), value: 171),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 10), value: 170),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 11), value: 171),
                ],
                band: 168...172, bandLabel: "your dry weight",
                annotation: SeriesAnnotation(date: MarcusFixtures.date(2026, 6, 8), label: "salty dinner — cleared in a day"),
                provenance: "From your morning scale, synced",
                explainReading: "This is your fluid early-warning. The little bump on the 8th was a salty meal — it cleared by morning, which is exactly the all-clear pattern we want.",
                explainNextStep: "Keep the same-time weigh-in. A jump that doesn't clear in a day is the one to tell me about.",
                explainAsk: "Want me to flag the next time the scale climbs and stays?"
            ),
            LabSeries(
                id: "bp", name: "Home blood pressure", unit: "mmHg",
                points: [
                    LabPoint(date: MarcusFixtures.date(2026, 6, 5), value: 132),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 7), value: 128),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 9), value: 126),
                    LabPoint(date: MarcusFixtures.date(2026, 6, 11), value: 124),
                ],
                band: 110...130, bandLabel: "the calm zone",
                annotation: nil,
                provenance: "From your home cuff",
                explainReading: "Your systolic readings, drifting gently into the calm zone — kind to a stiff heart and to the kidneys both.",
                explainNextStep: "The lisinopril and the low-sodium plan are doing this. Nothing to change.",
                explainAsk: "Want the cuff readings on Dr. Reyes's cardiology summary?"
            ),
        ],
        medications: [
            Medication(
                id: "empagliflozin", name: "Empagliflozin", dose: "10 mg · once daily",
                purposeLine: "protects heart and kidneys while steadying sugar",
                scheduleLine: "in the morning, with or without food",
                supplyDaysRemaining: 6, pharmacy: "CVS Peachtree",
                guidance: ["The one medicine doing three jobs — the cornerstone of your plan", "Stay hydrated; it works by passing a little sugar through your urine"],
                watchlist: ["Pause it during a stomach bug with poor intake — tell me and I'll flag the team", "Mention any yeast or urinary irritation; it's manageable"],
                history: ["10 mg daily — since Sep 2025 (added for heart + kidney protection)"],
                adherence30: [1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1]
            ),
            Medication(
                id: "metformin", name: "Metformin", dose: "1000 mg · twice daily",
                purposeLine: "steadies your blood sugar",
                scheduleLine: "with breakfast and dinner",
                supplyDaysRemaining: 19, pharmacy: "CVS Peachtree",
                guidance: ["Take with food — easier on your stomach", "Held automatically before any scan with contrast; we'll plan it"],
                watchlist: ["B12 gets checked yearly", "Stomach upset settled years ago for you"],
                history: ["1000 mg twice daily — since 2016", "500 mg twice daily — 2012 to 2016"],
                adherence30: [1,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1]
            ),
            Medication(
                id: "lisinopril", name: "Lisinopril", dose: "20 mg · once daily",
                purposeLine: "eases the heart's load and protects the kidneys",
                scheduleLine: "with breakfast",
                supplyDaysRemaining: 24, pharmacy: "CVS Peachtree",
                guidance: ["Morning is fine — consistency beats timing", "Go easy on ibuprofen; it works against this and your kidneys"],
                watchlist: ["A dry cough is the known quirk — mention it if it shows", "Potassium gets watched on your kidney panels"],
                history: ["20 mg daily — since 2024 (heart failure dose)", "10 mg daily — 2018 to 2024"],
                adherence30: [1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1]
            ),
            Medication(
                id: "furosemide", name: "Furosemide", dose: "20 mg · as directed",
                purposeLine: "sheds extra fluid before it strains the heart",
                scheduleLine: "mornings, or as Dr. Reyes adjusts for your weight",
                supplyDaysRemaining: 28, pharmacy: "CVS Peachtree",
                guidance: ["Take it early — it'll keep you close to a bathroom for a few hours", "Your weigh-in tells us whether the dose is right"],
                watchlist: ["Strong dizziness or cramping can mean it's pulled a little too much — tell me", "Dr. Reyes may flex the dose up on heavy-fluid days"],
                history: ["20 mg, weight-guided — since 2024"],
                adherence30: [1,1,0,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0]
            ),
        ],
        careTeam: [
            CareTeamMember(name: "Dr. Anita Shah", role: "Primary care", org: "Piedmont Internal Medicine · Privia"),
            CareTeamMember(name: "Dr. Lena Reyes", role: "Cardiology", org: "Emory Heart & Vascular"),
            CareTeamMember(name: "Dr. Samuel Okafor", role: "Nephrology", org: "Emory Healthcare"),
            CareTeamMember(name: "CVS Peachtree", role: "Pharmacy", org: "Peachtree St NE, Atlanta"),
        ],
        officePhone: "404-555-0173",
        officeName: "Dr. Shah's office",
        appointments: [],
        journeys: [
            Journey(
                title: "The morning weigh-in",
                why: "Same time, every day. It's the one habit that catches fluid before it ever catches you.",
                habits: [
                    AtomicHabit(
                        title: "Step on the scale, log the number",
                        contextLine: "after the bathroom, before coffee",
                        keptDates: (1...14).compactMap { $0 == 6 ? nil : Calendar.current.date(byAdding: .day, value: -$0, to: .now) }
                    )
                ],
                gardenSeed: 28
            ),
            Journey(
                title: "Good-breath movement",
                why: "Short, kind walks on the days your chest feels open — the heart likes them, and so does your sugar.",
                habits: [
                    AtomicHabit(
                        title: "A gentle 10-minute walk",
                        contextLine: "when the breath feels easy — never forced",
                        keptDates: (1...12).compactMap { $0 % 3 == 0 ? nil : Calendar.current.date(byAdding: .day, value: -$0, to: .now) }
                    )
                ],
                gardenSeed: 44
            ),
        ],
        insights: [
            Insight(
                category: .headsUp,
                headline: "Your kidneys are the next thing to protect — and we're early",
                body: "The risk model watched your sugar, pressure and that winter eGFR dip together and flagged kidneys as the one to guard now. Good news: the empagliflozin you already take is the protection. This is a head start, not a diagnosis.",
                confidence: "A population-level signal from your own trends — not a prediction about a date or outcome.",
                provenance: "Rumi risk model · your Emory + Piedmont labs",
                actionLabel: "See what protects them",
                status: .fresh,
                visual: .chart("egfr"),
                sources: ["eGFR trend (3 panels)", "A1c + home BP", "CKD risk factors on your record"]
            ),
            Insight(
                category: .pattern,
                headline: "Salty dinners show up on tomorrow's scale",
                body: "Three times now, a higher-sodium dinner has nudged your morning weight up a pound or two — then cleared by the next day. Your body keeps the receipts, gently, and the pattern is a useful one to know.",
                confidence: "Seen 3 of the last 4 salty meals — enough to notice.",
                provenance: "Your meal logs + morning weights",
                actionLabel: "See the low-sodium swaps",
                status: .fresh,
                visual: .chart("weight"),
                sources: ["Daily weight (14 days)", "Meal logs with sodium notes"]
            ),
            Insight(
                category: .milestone,
                headline: "Two steady weeks — heart and sugar both",
                body: "Fourteen days within a pound, A1c holding at 7.1, blood pressure drifting calm. With three conditions in the room, a stretch this quiet is the whole goal. Say it out loud.",
                confidence: nil,
                provenance: "Your scale, cuff and last lab",
                actionLabel: "See the journey",
                status: .fresh,
                visual: .scene(22),
                sources: ["Daily weight (14 days)", "Home BP (this week)", "A1c (Mar 14)"]
            ),
        ],
        storyEvents: [
            StoryEvent(kind: .milestone, date: MarcusFixtures.date(2026, 6, 9), title: "Two steady weeks", detail: "Weight within a pound, breath easy. Three conditions, one quiet stretch."),
            StoryEvent(kind: .companion, date: MarcusFixtures.date(2026, 3, 20), title: "We caught the kidney risk early", detail: "The risk model flagged it from your trends — and your medicine already protects it."),
            StoryEvent(kind: .result, date: MarcusFixtures.date(2026, 3, 14), title: "A1c 7.1 · eGFR holding at 66", detail: "Sugar near target, kidneys steady. The plan is working on all three."),
            StoryEvent(kind: .visit, date: MarcusFixtures.date(2026, 2, 10), title: "Cardiology · Dr. Reyes", detail: "Heart stable; furosemide kept weight-guided. “Keep weighing in.”"),
            StoryEvent(kind: .milestone, date: MarcusFixtures.date(2025, 9, 20), title: "Started empagliflozin", detail: "One medicine, three jobs — the turn this year's stability was built on."),
            StoryEvent(kind: .diagnosis, date: MarcusFixtures.date(2024, 5, 2), title: "Heart failure, preserved EF", detail: "Where the daily weigh-in became the most important habit."),
            StoryEvent(kind: .diagnosis, date: MarcusFixtures.date(2012, 7, 16), title: "Type 2 diabetes", detail: "The diagnosis that started the long road."),
        ],
        currents: [
            CurrentsPiece(
                format: .glance, kicker: "For your heart",
                headline: "Why your weight is a heart number",
                body: "In preserved-EF heart failure, the scale is your earliest warning. A 2–3 lb overnight jump usually isn't fat — it's fluid the stiff heart is struggling to move. Catch it early and a phone call fixes it; miss it and it becomes a hard week.",
                sceneSeed: 7, imageName: "currents_kidney", aiGenerated: true,
                intent: "heart-understanding · fluid awareness"
            ),
            CurrentsPiece(
                format: .read, kicker: "One pill, three jobs",
                headline: "How empagliflozin protects all of you",
                body: "It started as a diabetes drug. Then the data surprised everyone.\n\nEmpagliflozin nudges your kidneys to pass a little extra sugar — and with it, a little extra sodium and water. That gentle offloading eases the heart's workload and lowers the pressure inside the kidney's tiny filters.\n\nThe result is rare: one daily pill that steadies your sugar, protects a stiff heart, and slows kidney strain at the same time. For a body managing all three, it's the cornerstone — which is why a gap in the refill matters more here than almost anywhere.",
                sceneSeed: 3, imageName: "currents_kidney", aiGenerated: true,
                intent: "med-understanding · SGLT2 adherence"
            ),
            CurrentsPiece(
                format: .glance, kicker: "Small swap",
                headline: "The salt that hides in 'healthy'",
                body: "A single bowl of canned soup or deli turkey can carry a day's sodium — and tomorrow's water weight. The swap isn't blandness; it's lemon, herbs, garlic and pepper doing the work salt used to.",
                sceneSeed: 21, imageName: "currents_salt", aiGenerated: true,
                intent: "low-sodium living"
            ),
            CurrentsPiece(
                format: .listen, kicker: "Two minutes, spoken",
                headline: "Living well with three at once",
                body: "A short listen on what it means to manage more than one condition — and why treating them as one story, not three to-do lists, is the kindest thing you can do for yourself.",
                sceneSeed: 14, imageName: "currents_father_son", aiGenerated: true,
                intent: "relational · multi-condition life"
            ),
        ],
        moments: [
            Moment(
                kind: .habit,
                title: "Weigh-in — your daily all-clear",
                body: "Same time, before coffee. One number that tells your heart team you're steady.",
                actionLabel: "Logged it"
            ),
            Moment(
                kind: .task,
                title: "Empagliflozin runs low in 6 days",
                body: "It's the one guarding heart and kidneys both — let's not let it gap. The refill's ready at CVS.",
                actionLabel: "Make it ready",
                medID: "empagliflozin"
            ),
            Moment(
                kind: .insight,
                title: "Your kidneys, protected early",
                body: "The risk model caught the trend before it became a problem. Worth seeing what's holding it steady.",
                actionLabel: "Show me"
            ),
        ],
        statusQuiet: "Three conditions, one quiet day. Take it.",
        statusBusy: "A few things worth your time — heart, sugar, kidneys, handled together.",
        guideSeed: [
            GuideItem(kind: .question, text: "Is my furosemide dose right, or should it flex with my weight?",
                      addedFrom: "From your fluid logs · this week"),
            GuideItem(kind: .observation, text: "Two steady weeks on the scale — the low-sodium plan is landing.",
                      addedFrom: "From your morning weigh-ins"),
            GuideItem(kind: .question, text: "Should cardiology and nephrology compare notes on my next eGFR?",
                      addedFrom: "From the kidney-risk heads-up"),
        ]
    )

    // MARK: - Symptom support plans (the L5 brain, fixture-scripted)

    /// Every log gets a real response — support, tips that fit the condition,
    /// and paths that go somewhere. Severity shapes the urgency honestly.
    static func supportPlan(pathway: CarePathway, kind: String, severity: Double) -> SupportPlan {
        let high = severity >= 0.65
        switch pathway {
        case .metabolic:
            return metabolicSupport(kind: kind, high: high)
        case .oncology:
            return oncologySupport(kind: kind, high: high)
        case .procedure:
            return procedureSupport(kind: kind, high: high)
        case .cardiometabolic:
            return cardiometabolicSupport(kind: kind, high: high)
        }
    }

    private static func metabolicSupport(kind: String, high: Bool) -> SupportPlan {
        switch kind {
        case "Dizziness":
            return SupportPlan(
                message: high
                    ? "That's a lot of dizziness, and I don't want to shrug at it. With lisinopril in the picture, strong dizzy spells are worth a same-day call — it can mean your dose is working harder than it needs to."
                    : "Noted. Dizziness with your meds is usually about standing up fast, a light breakfast, or a low-water shift — but it's worth keeping an eye on together.",
                tips: [
                    "Sit or stand up in two stages for the next day — bed, edge, then up",
                    "Check your BP and a glucose reading if you can; I'll fold them in",
                    "Water first, coffee second on warehouse mornings",
                ],
                urgent: high,
                guideQuestion: "Dizzy spells \(high ? "(strong ones)" : "")— could lisinopril dosing be part of it?",
                draftMessage: "Marcus logged \(high ? "significant" : "mild") dizziness today. Home BP and meds list attached. Could someone advise whether his lisinopril dose should be reviewed?"
            )
        case "Leg cramps":
            return SupportPlan(
                message: "Logged — and it fits the pattern we've been watching: cramps cluster on nights the statin drifts late. Four of five times now.",
                tips: [
                    "Gentle calf stretch before bed tonight",
                    "Water through the evening — cramps love a dry day",
                    "Note tonight's statin time; the pattern gets sharper with each log",
                ],
                urgent: false,
                guideQuestion: "Leg cramps keep clustering on late-statin nights — worth a timing change?",
                draftMessage: "Marcus has logged recurring leg cramps that cluster on late atorvastatin doses (4 of 5 instances). Could the dosing time be reviewed at the next visit?"
            )
        case "Foot tingling":
            return SupportPlan(
                message: high
                    ? "Strong tingling in the feet deserves real attention with your diabetes — not panic, attention. Let's get it in front of Dr. Patterson properly."
                    : "Logged, with its place on the map. Tingling that comes and goes is common; the pattern over weeks is what we watch.",
                tips: [
                    "A quick look at both feet tonight — any new marks or pressure spots",
                    "Comfortable shoes on shift days this week",
                    "Log it again when it happens; location + timing builds the picture",
                ],
                urgent: high,
                guideQuestion: "Foot tingling \(high ? "getting stronger" : "on and off") — time for a sensation check?",
                draftMessage: "Marcus logged \(high ? "significant" : "intermittent") foot tingling. Given his T2D, could a foot sensation check be added to his June 24 visit?"
            )
        default:
            return SupportPlan(
                message: high
                    ? "That sounds genuinely rough, and it's logged where it counts. If this keeps its grip through tomorrow, the office should hear about it — I can set that up in one tap."
                    : "Got it — logged and woven in. If a pattern forms, you'll hear it from me first.",
                tips: [
                    "Nothing to fix tonight — rest is allowed to be the whole plan",
                    "If it shifts or sharpens, log it again; trends beat memories",
                ],
                urgent: high,
                guideQuestion: "\(kind) — \(high ? "hit hard recently" : "showing up sometimes"); worth discussing?",
                draftMessage: "Marcus logged \(kind.lowercased()) (\(high ? "significant" : "mild")) today and wanted the office to be aware."
            )
        }
    }

    private static func oncologySupport(kind: String, high: Bool) -> SupportPlan {
        switch kind {
        case "Fever or chills":
            return SupportPlan(
                message: "Fever during chemo is the one symptom we never sit on. If the thermometer reads 100.4°F or higher, call Dr. Rivera's team now — any hour. They expect these calls; it's what the on-call line is for.",
                tips: [
                    "Take your temperature now if you haven't — the number decides everything",
                    "100.4°F or higher → call immediately, even at 3am",
                    "Under 100.4 → recheck in an hour, rest, fluids, and log it",
                ],
                urgent: true,
                guideQuestion: "Fever episode this cycle — does my threshold or plan change for cycle 4?",
                draftMessage: "Elena logged fever/chills (cycle 3, day 6). Temperature reading and timing attached. Please advise."
            )
        case "Nausea":
            return SupportPlan(
                message: high
                    ? "Breakthrough nausea this strong means the plan needs reinforcements — not that you need more grit. The team has stronger options; they just need to hear it's breaking through."
                    : "Logged. Day-by-day nausea is cycle 3 doing its thing — your scheduled ondansetron is still the best tool, taken on time rather than after.",
                tips: [
                    "Cold food, small portions — smell is half the battle",
                    "Next ondansetron on schedule, not when it gets bad",
                    "Sips count: ice chips, ginger tea, watered juice",
                ],
                urgent: high,
                guideQuestion: high ? "Nausea broke through the schedule — can we add a second-line anti-nausea med?" : "Nausea pattern this cycle — any tweaks for cycle 4?",
                draftMessage: "Elena is logging \(high ? "breakthrough" : "manageable") nausea on her scheduled regimen (cycle 3). \(high ? "Could the anti-nausea plan be escalated?" : "For the record ahead of cycle 4 planning.")"
            )
        case "Tingling hands/feet":
            return SupportPlan(
                message: "Logged with its place on the map. Tingling in hands or feet during taxane cycles is exactly the thing Dr. Rivera asks about — it's how dosing decisions get made, so every log here genuinely matters.",
                tips: [
                    "Note when it's strongest — morning, evening, after cold",
                    "Mention buttons, jar lids, or dropped keys — function details help the team",
                    "Keep hands and feet warm; cold makes it louder",
                ],
                urgent: high,
                guideQuestion: "Tingling \(high ? "is interfering with daily things" : "comes and goes") — does the cycle 4 dose need adjusting?",
                draftMessage: "Elena is logging \(high ? "function-affecting" : "intermittent") tingling in hands/feet. Location log attached for neuropathy review before cycle 4."
            )
        case "Fatigue":
            return SupportPlan(
                message: high
                    ? "Heavy-limbed days this deep in the cycle are real — your counts are near their low. Rest isn't giving up; this week, rest is the assignment."
                    : "Logged. Day-6 tiredness is right on your cycle's usual curve — the turn toward better days is close.",
                tips: [
                    "Naps without guilt — fatigue debt collects interest",
                    "On a better moment, ten gentle minutes of walking softens the next dip",
                    "Protein at breakfast helps more than it should",
                ],
                urgent: false,
                guideQuestion: "Fatigue pattern this cycle — anything worth checking (thyroid, blood counts)?",
                draftMessage: "Elena is logging notable fatigue (cycle 3). Pattern attached for review at the next visit."
            )
        default:
            return SupportPlan(
                message: high
                    ? "That's a hard one, and you didn't carry it alone — it's logged, and the team can hear about it today if you want."
                    : "Logged, gently. Treatment weeks hold a lot; naming it is part of getting through it.",
                tips: [
                    "Nothing needs solving this minute",
                    "If it's still loud tomorrow, we tell the team together — one tap",
                ],
                urgent: high,
                guideQuestion: "\(kind) during cycle 3 — normal course, or worth a closer look?",
                draftMessage: "Elena logged \(kind.lowercased()) (\(high ? "significant" : "mild")) during cycle 3 and wanted the care team aware."
            )
        }
    }

    private static func procedureSupport(kind: String, high: Bool) -> SupportPlan {
        switch kind {
        case "Knee pain":
            return SupportPlan(
                message: high
                    ? "A hard pain day twelve days out — frustrating, but it changes nothing about the plan. Acetaminophen is your green-lit option; the ibuprofen shortcut is the one we can't take this close."
                    : "Logged with its spot on the map. Pain that wobbles day to day is the knee being itself — your trend is still two points better on prehab days.",
                tips: [
                    "Acetaminophen is surgery-safe — ibuprofen is not, from June 16",
                    "Ice 15 minutes after today's walk",
                    "Shorter walk today beats no walk",
                ],
                urgent: false,
                guideQuestion: high ? "Bad pain days before surgery — anything stronger that's still pre-op safe?" : "Pain trend before surgery — on track?",
                draftMessage: "Sam logged \(high ? "a high-pain day" : "knee pain") ahead of the June 23 surgery. Trend attached for the pre-op visit."
            )
        case "Swelling":
            return SupportPlan(
                message: high
                    ? "Notable swelling close to surgery is worth a quick call to Dr. Chen's office today — usually it's nothing, but pre-op is when they want to know."
                    : "Logged with location. Elevation and ice tonight; the pre-op visit Tuesday can take a look.",
                tips: [
                    "Foot above heart for 20 minutes this evening",
                    "Ice wrapped in a towel, 15 minutes on",
                    "Compare both legs — one-sided swelling is the call-worthy kind",
                ],
                urgent: high,
                guideQuestion: "Swelling before surgery — anything to rule out at the pre-op visit?",
                draftMessage: "Sam logged \(high ? "notable" : "mild") knee swelling ahead of the June 23 procedure. Photo/location attached — please advise if he should be seen before Tuesday."
            )
        case "Worry":
            return SupportPlan(
                message: "Twelve days out is exactly when this shows up — for almost everyone. You're not behind on courage; you're on schedule. Want to walk through the day-of timeline together? Known beats imagined, every time.",
                tips: [
                    "The day-of timeline is in your prep — most of it is waiting and warm blankets",
                    "Write the 2am questions in your discussion guide; Tuesday's visit answers them",
                    "Sleep tonight beats research tonight",
                ],
                urgent: false,
                guideQuestion: "What does the anesthesia conversation look like — spinal vs general, and who decides?",
                draftMessage: "Sam has some pre-op questions ahead of Tuesday's visit and wanted them flagged for a few extra minutes."
            )
        default:
            return SupportPlan(
                message: high
                    ? "Logged — and close to surgery, the office would rather hear one extra thing than one too few. I can send it over or set up the call."
                    : "Logged. The countdown plan holds; this goes in the record where Tuesday's visit can see it.",
                tips: [
                    "Rest tonight — prehab counts tomorrow too",
                    "Anything that feels new or one-sided is worth a call, not a worry",
                ],
                urgent: high,
                guideQuestion: "\(kind) before surgery — anything it changes?",
                draftMessage: "Sam logged \(kind.lowercased()) (\(high ? "significant" : "mild")) ahead of the June 23 surgery, for the record."
            )
        }
    }

    private static func cardiometabolicSupport(kind: String, high: Bool) -> SupportPlan {
        switch kind {
        case "Shortness of breath":
            return SupportPlan(
                message: high
                    ? "Breathlessness like this with your heart is the one we don't sit on. If it's new, worse lying flat, or comes with a fast weight jump, call Dr. Reyes's team now — any hour. That's exactly what the line is for."
                    : "Logged, and I'm watching it with your heart in mind. A little breathlessness on exertion can be ordinary — but paired with the scale climbing, it's the early sign we act on together.",
                tips: [
                    "Check your weight now — a jump alongside this is the call-worthy combination",
                    "Can you lie flat comfortably tonight? If not, that's worth telling the team",
                    "Sit upright, slow the breath; log how many blocks or stairs brought it on",
                ],
                urgent: high,
                guideQuestion: "Shortness of breath \(high ? "that's new or worse" : "on exertion") — does my fluid plan or furosemide need a look?",
                draftMessage: "Rosa logged \(high ? "significant" : "mild") shortness of breath. Today's weight and recent trend attached for the heart team — please advise."
            )
        case "Weight jump", "Swelling":
            return SupportPlan(
                message: high
                    ? "A real jump on the scale or swelling that's climbing is fluid — and with your heart, that's a same-day call to Dr. Reyes's office, not a wait. Caught today, it's a phone fix."
                    : "Logged with care. A small bump that clears by morning is usually a salty meal; one that holds two days running is the fluid signal we tell the team about.",
                tips: [
                    "Weigh again tomorrow, same time — the trend decides everything",
                    "Go light on salt today; check both ankles for one-sided swelling",
                    "If you're up 3 lb overnight or 5 in a week, that's the call line",
                ],
                urgent: high,
                guideQuestion: "Fluid showing on the scale — should furosemide flex on heavy days?",
                draftMessage: "Rosa logged \(high ? "a notable" : "a small") weight/fluid change. Daily-weight trend attached for Dr. Reyes — does the diuretic plan need adjusting?"
            )
        case "Dizziness":
            return SupportPlan(
                message: high
                    ? "Strong dizziness deserves attention with your heart meds in the mix — lisinopril and furosemide can pull pressure or fluid a touch low. Worth a same-day call so we get the balance right."
                    : "Noted, and held against your meds. Standing up slowly helps; if it pairs with a low weight or strong thirst, the furosemide may have done a little too much.",
                tips: [
                    "Stand in two stages today — edge of the bed, then up",
                    "Check your weight and a BP reading; I'll fold them in",
                    "Sip water through the day unless the team has capped your fluids",
                ],
                urgent: high,
                guideQuestion: "Dizzy spells \(high ? "(strong ones)" : "") — could the furosemide or lisinopril dose be part of it?",
                draftMessage: "Rosa logged \(high ? "significant" : "mild") dizziness. Recent weight and BP attached — could the diuretic/ACE balance be reviewed?"
            )
        case "Foot tingling":
            return SupportPlan(
                message: high
                    ? "Strong tingling deserves real attention with your diabetes — not panic, attention. Let's get it in front of Dr. Shah properly."
                    : "Logged, with its place on the map. Tingling that comes and goes is common with long-standing diabetes; the pattern over weeks is what we watch.",
                tips: [
                    "A quick look at both feet tonight — any new marks or pressure spots",
                    "Comfortable shoes this week",
                    "Log it again when it happens; location + timing builds the picture",
                ],
                urgent: high,
                guideQuestion: "Foot tingling \(high ? "getting stronger" : "on and off") — time for a sensation check?",
                draftMessage: "Rosa logged \(high ? "significant" : "intermittent") foot tingling. Given her long-standing T2D, could a foot sensation check be added?"
            )
        default:
            return SupportPlan(
                message: high
                    ? "That sounds genuinely rough, and it's logged where it counts. With three things in the room, one extra call beats one too few — I can set it up in a tap."
                    : "Got it — logged and woven in across your heart, sugar and kidney picture. If a pattern forms, you'll hear it from me first.",
                tips: [
                    "Nothing to fix tonight — rest is allowed to be the whole plan",
                    "If it shifts or sharpens, log it again; trends beat memories",
                ],
                urgent: high,
                guideQuestion: "\(kind) — \(high ? "hit hard recently" : "showing up sometimes"); worth discussing?",
                draftMessage: "Rosa logged \(kind.lowercased()) (\(high ? "significant" : "mild")) today and wanted the office to be aware."
            )
        }
    }
}
