import Foundation

/// The Care hub fixture corpus (§7.4) — production-shaped clinical data for all
/// three pathways, so Care is fully navigable and never a dead-end for Marcus,
/// Elena, or Sam. One bundle re-seeds every Care surface when the pathway
/// changes, exactly like the rest of the persona spine.
struct CareBundle {
    let threads: [MessageThread]
    let appointments: [Appointment]
    let bills: [Bill]
    let cost: CostSummary
    let documents: [CareDocument]
    let savings: [MedicationSaving]
    let requestsSeed: [CareRequest]
    /// A new significant result the user hasn't acknowledged yet (REC-5).
    let resultToAck: (title: String, detail: String, series: String?)?
    /// Population-level, route-to-care nudge — nil where it would be unkind
    /// (mid-treatment) or forced (§4.10).
    let lookingAhead: LookingAheadNudge?
}

enum CareHubFixtures {
    static func bundle(for pathway: CarePathway) -> CareBundle {
        switch pathway {
        case .metabolic: return marcus
        case .oncology: return elena
        case .procedure: return sam
        case .cardiometabolic: return rosa
        }
    }

    private static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10, _ min: Int = 0) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
        return Calendar.current.date(from: c) ?? .now
    }

    private static func hoursAgo(_ h: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: -h, to: .now) ?? .now
    }

    private static func departBy(_ appt: Date, travel: Int, buffer: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: -(travel + buffer), to: appt) ?? appt
    }

    // MARK: - Marcus · metabolic (T2D · HTN · CKD-2)

    static let marcus: CareBundle = {
        let pattersonVisit = date(2026, 6, 24, 10, 30)
        let nephTelehealth = date(2026, 7, 1, 14, 0)

        let threads: [MessageThread] = [
            MessageThread(
                practice: "Piedmont Internal Medicine",
                memberName: "Dr. Patterson's office",
                memberRole: "Primary care · Privia",
                mode: .inApp,
                category: .medical,
                messages: [
                    CareMessage(author: .user, text: "The leg cramps keep landing on nights I take the statin late. Worth changing the timing?", at: hoursAgo(30), state: .delivered, origin: "From the pattern we caught · May 26"),
                    CareMessage(author: .team, text: "Good catch, Marcus — moving atorvastatin to dinnertime is reasonable. Let's confirm it at your June 24 visit and keep logging the cramps until then.", at: hoursAgo(4), state: .delivered),
                ],
                unread: true
            ),
            MessageThread(
                practice: "CVS Peachtree",
                memberName: "CVS Peachtree",
                memberRole: "Pharmacy",
                mode: .inApp,
                category: .refill,
                messages: [
                    CareMessage(author: .team, text: "Your atorvastatin refill is ready for pickup. Want it switched to free delivery? Just reply here.", at: hoursAgo(20), state: .delivered),
                ],
                unread: false
            ),
            MessageThread(
                practice: "Emory Healthcare",
                memberName: "Dr. Okafor (Nephrology)",
                memberRole: "Kidney care · MyChart",
                mode: .portal,
                category: .medical,
                messages: [
                    CareMessage(author: .team, text: "Your March kidney panel looked stable. No changes needed — see you at the telehealth check on July 1.", at: hoursAgo(60), state: .delivered),
                ],
                unread: false
            ),
        ]

        let appointments: [Appointment] = [
            Appointment(
                with: "Dr. Alicia Patterson", date: pattersonVisit,
                location: "Piedmont Internal Medicine", prepReady: true,
                kind: .inPerson, status: .confirmed, joinLink: nil,
                trip: TripPlan(
                    departBy: departBy(pattersonVisit, travel: 18, buffer: 20),
                    travelMinutes: 18,
                    routeHint: "18 min drive · usually light mid-morning",
                    destinationDetail: "Piedmont Internal Medicine · 3rd floor, Suite 320 · Lot B parking",
                    mapQuery: "Piedmont Internal Medicine Atlanta",
                    checklist: ["Insurance card", "$42 copay (or Apple Pay on file)", "Home BP cuff readings — I'll have them charted", "The atorvastatin-timing question"],
                    rideHint: "It's a short drive, but I can line up a ride if the truck's acting up."
                ),
                planGoalHint: "Reviews your A1c trend and the home-BP goal"
            ),
            Appointment(
                with: "Dr. Samuel Okafor · Nephrology", date: nephTelehealth,
                location: "Telehealth · Emory video visit", prepReady: false,
                kind: .telehealth, status: .confirmed,
                joinLink: "https://emory.example/visit/marcus",
                trip: TripPlan(
                    departBy: nephTelehealth,
                    travelMinutes: 0,
                    routeHint: "Join from home",
                    destinationDetail: "Emory video visit",
                    mapQuery: "",
                    checklist: ["A quiet spot with good signal", "Your latest home BP readings", "Any questions about the kidney panel"],
                    isVirtual: true
                ),
                planGoalHint: "Checks in on kidney protection"
            ),
        ]

        let bills: [Bill] = [
            Bill(
                key: "piedmont|mar12-visit",
                provider: "Piedmont Internal Medicine",
                encounter: "Office visit · Mar 12, 2026",
                statementDate: date(2026, 4, 1),
                dueDate: date(2026, 6, 30),
                status: .open,
                amount: 42,
                lineItems: [
                    BillLineItem(label: "Established patient visit", billed: 186, planPaid: 144, youOwe: 42, reason: "Specialist copay"),
                    BillLineItem(label: "Metabolic panel", billed: 96, planPaid: 96, youOwe: 0, reason: "Preventive — covered in full"),
                ],
                plainSummary: "This is the $42 copay from your March visit. Insurance covered the rest, including the labs. Nothing here looks off.",
                flag: nil,
                source: "Piedmont statement · Apr 1"
            ),
            Bill(
                key: "quest|mar12-labs",
                provider: "Quest Diagnostics",
                encounter: "Lab draw · Mar 12, 2026",
                statementDate: date(2026, 3, 28),
                dueDate: nil,
                status: .paid,
                amount: 0,
                lineItems: [
                    BillLineItem(label: "A1c + lipid panel", billed: 120, planPaid: 120, youOwe: 0, reason: "Preventive — covered in full"),
                ],
                plainSummary: "Fully covered. No action needed — it's here so the record is complete.",
                flag: nil,
                source: "Quest EOB · Mar 28"
            ),
        ]

        let cost = CostSummary(
            planName: "Anthem Blue · PPO",
            deductibleMet: 640, deductibleTotal: 1500,
            oopMet: 980, oopTotal: 4000,
            upcomingEstimate: 42,
            upcomingLabel: "June 24 visit copay (estimate)"
        )

        let documents: [CareDocument] = [
            CareDocument(title: "Insurance card", type: .insuranceCard, capturedAt: date(2026, 1, 8), source: "From your scan", pageCount: 2,
                         fields: [ExtractedField(label: "Member ID", value: "ABC123456789"), ExtractedField(label: "Group", value: "PIEDMONT-PPO"), ExtractedField(label: "Plan", value: "Anthem Blue PPO")], confirmed: true),
            CareDocument(title: "Eye exam summary", type: .labResult, capturedAt: date(2025, 11, 20), source: "From your scan",
                         fields: [ExtractedField(label: "Result", value: "Normal · no retinopathy"), ExtractedField(label: "Repeat", value: "Yearly")], confirmed: true),
        ]

        let savings: [MedicationSaving] = [
            MedicationSaving(medID: "atorvastatin", kind: .cashPrice, title: "GoodRx cash price at CVS Peachtree", estimateLine: "about $9/month with the coupon", basis: "Pharmacy cash-price comparison · your CVS", sponsor: nil, requiresPII: false),
            MedicationSaving(medID: "metformin", kind: .alternative, title: "Already the generic — about as low as it goes", estimateLine: "around $4/month on your plan", basis: "Your formulary tier · informational only", sponsor: nil, requiresPII: false),
        ]

        let requests: [CareRequest] = [
            CareRequest(kind: .refill, subject: "Atorvastatin 20 mg", detail: "Refill ready — pickup or delivery", state: .acknowledged, at: hoursAgo(20), routedTo: "CVS Peachtree (in-app)"),
        ]

        return CareBundle(
            threads: threads,
            appointments: appointments,
            bills: bills,
            cost: cost,
            documents: documents,
            savings: savings,
            requestsSeed: requests,
            resultToAck: ("A1c — 8.4%", "Down from 8.7 in December — fifth drop in a row.", "a1c"),
            lookingAhead: LookingAheadNudge(
                headline: "A screening worth a conversation",
                body: "People managing diabetes for several years sometimes benefit from a kidney-protection medication review. It may be worth asking Dr. Patterson whether it fits you.",
                basis: "This is a general, population-level suggestion based on living with type 2 diabetes — not a prediction about you, and no number or date is implied.",
                guideQuestion: "Is there a kidney-protective medication (like an SGLT2) worth considering for me?"
            )
        )
    }()

    // MARK: - Elena · oncology (breast cancer · AC-T · cycle 3 of 6)

    static let elena: CareBundle = {
        let cycle4 = date(2026, 6, 22, 9, 0)
        let riveraVisit = date(2026, 7, 6, 11, 0)
        let navigatorCheck = date(2026, 6, 18, 15, 0)

        let threads: [MessageThread] = [
            MessageThread(
                practice: "Northside Cancer Institute",
                memberName: "Dr. Rivera's team",
                memberRole: "Oncology",
                mode: .inApp,
                category: .medical,
                messages: [
                    CareMessage(author: .user, text: "Cycle 3 went so much better with the scheduled ondansetron. Can we keep the same plan for cycle 4?", at: hoursAgo(40), state: .delivered, origin: "Added after cycle 3 went smoothly"),
                    CareMessage(author: .team, text: "Absolutely — we'll keep the same anti-nausea schedule. I've noted it for cycle 4 on the 22nd. Proud of how you're navigating this, Elena.", at: hoursAgo(6), state: .delivered),
                ],
                unread: true
            ),
            MessageThread(
                practice: "Northside Cancer Institute",
                memberName: "Nia Coleman, RN",
                memberRole: "Infusion nurse navigator",
                mode: .inApp,
                category: .medical,
                messages: [
                    CareMessage(author: .team, text: "Reminder: your low-count window opens around day 7. Keep the thermometer close — 100.4°F or higher is a call-us-now, any hour.", at: hoursAgo(18), state: .delivered),
                ],
                unread: false
            ),
            MessageThread(
                practice: "Northside Pharmacy",
                memberName: "Northside Pharmacy",
                memberRole: "Pharmacy",
                mode: .inApp,
                category: .refill,
                messages: [
                    CareMessage(author: .team, text: "Your ondansetron and dexamethasone are stocked and ready ahead of cycle 4. No action needed.", at: hoursAgo(50), state: .delivered),
                ],
                unread: false
            ),
        ]

        let appointments: [Appointment] = [
            Appointment(
                with: "Cycle 4 infusion · Dr. Rivera's team", date: cycle4,
                location: "Northside Infusion Center", prepReady: true,
                kind: .inPerson, status: .confirmed,
                trip: TripPlan(
                    departBy: departBy(cycle4, travel: 25, buffer: 30),
                    travelMinutes: 25,
                    routeHint: "25 min drive · leave a buffer, infusion days run long",
                    destinationDetail: "Northside Infusion Center · 2nd floor · valet available at the main entrance",
                    mapQuery: "Northside Infusion Center Atlanta",
                    checklist: ["Insurance card", "A warm layer — infusion rooms run cold", "Something to pass the time (3–4 hrs)", "Pre-meds taken this morning", "A driver for the way home"],
                    rideHint: "You shouldn't drive yourself home after infusion — want me to help arrange a ride?"
                ),
                planGoalHint: "Cycle 4 of 6 — anti-nausea plan carried over from cycle 3"
            ),
            Appointment(
                with: "Nia Coleman, RN · symptom check", date: navigatorCheck,
                location: "Telehealth · Northside video visit", prepReady: false,
                kind: .telehealth, status: .confirmed,
                joinLink: "https://northside.example/visit/elena",
                trip: TripPlan(
                    departBy: navigatorCheck,
                    travelMinutes: 0, routeHint: "Join from home",
                    destinationDetail: "Northside video visit",
                    mapQuery: "",
                    checklist: ["Your symptom log this cycle", "The tingling notes since cycle 2", "A quiet, well-lit spot"],
                    isVirtual: true
                ),
                planGoalHint: "Checks the low-count window plan with you"
            ),
            Appointment(
                with: "Dr. Maya Rivera", date: riveraVisit,
                location: "Northside Cancer Institute", prepReady: false,
                kind: .inPerson, status: .confirmed,
                planGoalHint: "Mid-treatment review"
            ),
        ]

        let bills: [Bill] = [
            Bill(
                key: "northside|cycle2-infusion",
                provider: "Northside Cancer Institute",
                encounter: "Cycle 2 infusion · Apr 20, 2026",
                statementDate: date(2026, 5, 10),
                dueDate: date(2026, 7, 15),
                status: .open,
                amount: 180,
                lineItems: [
                    BillLineItem(label: "Chemotherapy administration", billed: 4200, planPaid: 4020, youOwe: 180, reason: "20% coinsurance after deductible"),
                    BillLineItem(label: "Anti-nausea medications", billed: 320, planPaid: 320, youOwe: 0, reason: "Covered in full"),
                ],
                plainSummary: "Most of this is covered. Your share is the $180 coinsurance on the infusion. There's no rush — the due date is in July, and financial counseling at Northside can set up a payment plan if that helps.",
                flag: nil,
                source: "Northside statement · May 10"
            ),
            Bill(
                key: "northside|cycle1-infusion",
                provider: "Northside Cancer Institute",
                encounter: "Cycle 1 infusion · Feb 16, 2026",
                statementDate: date(2026, 3, 8),
                dueDate: nil,
                status: .paid,
                amount: 0,
                lineItems: [
                    BillLineItem(label: "Chemotherapy administration", billed: 4200, planPaid: 4200, youOwe: 0, reason: "Applied to deductible — now met"),
                ],
                plainSummary: "This one's settled. It's also the bill that met your deductible for the year, which is why your share dropped after it.",
                flag: nil,
                source: "Northside EOB · Mar 8"
            ),
        ]

        let cost = CostSummary(
            planName: "Aetna · Choice POS II",
            deductibleMet: 2000, deductibleTotal: 2000,
            oopMet: 3600, oopTotal: 6000,
            upcomingEstimate: 180,
            upcomingLabel: "Cycle 4 coinsurance (estimate)"
        )

        let documents: [CareDocument] = [
            CareDocument(title: "Insurance card", type: .insuranceCard, capturedAt: date(2026, 2, 1), source: "From your scan", pageCount: 2,
                         fields: [ExtractedField(label: "Member ID", value: "AET88810231"), ExtractedField(label: "Plan", value: "Aetna Choice POS II")], confirmed: true),
            CareDocument(title: "Chemo schedule handout", type: .form, capturedAt: date(2026, 2, 14), source: "From your scan",
                         fields: [ExtractedField(label: "Regimen", value: "AC-T · 6 cycles"), ExtractedField(label: "Cadence", value: "Every 3 weeks")], confirmed: true),
        ]

        let savings: [MedicationSaving] = [
            MedicationSaving(medID: "ondansetron", kind: .copayCard, title: "Manufacturer copay card", estimateLine: "about $25/month less", basis: "Manufacturer program · eligibility independent of sponsorship", sponsor: "Helsinn", requiresPII: true),
            MedicationSaving(medID: "ondansetron", kind: .cashPrice, title: "Cash price at Northside Pharmacy", estimateLine: "around $12 for the generic", basis: "Pharmacy cash-price comparison", sponsor: nil, requiresPII: false),
        ]

        let requests: [CareRequest] = [
            CareRequest(kind: .form, subject: "FMLA paperwork", detail: "Treatment dates letter for employer", state: .submitted, at: hoursAgo(72), routedTo: "Dr. Rivera's office (in-app)"),
        ]

        return CareBundle(
            threads: threads,
            appointments: appointments,
            bills: bills,
            cost: cost,
            documents: documents,
            savings: savings,
            requestsSeed: requests,
            resultToAck: ("Counts recovered — ANC 1.7", "Right on time, third cycle running.", "anc"),
            lookingAhead: nil   // mid-treatment: looking-ahead nudges are unkind here (§4.10)
        )
    }()

    // MARK: - Sam · procedure (knee replacement · 12 days out)

    static let sam: CareBundle = {
        let preOp = date(2026, 6, 17, 9, 0)
        let surgery = date(2026, 6, 23, 6, 30)
        let ptConsult = date(2026, 6, 19, 13, 0)

        let threads: [MessageThread] = [
            MessageThread(
                practice: "Midtown Orthopedics",
                memberName: "Dr. Chen's office",
                memberRole: "Orthopedic surgery",
                mode: .inApp,
                category: .medical,
                messages: [
                    CareMessage(author: .user, text: "Just to be sure — do I stop the ibuprofen the morning of the 16th or the night before?", at: hoursAgo(26), state: .delivered, origin: "From the NSAID heads-up · Jun 11"),
                    CareMessage(author: .team, text: "Stop after your last dose on the 15th — so none on the 16th onward. Acetaminophen is fine right up to surgery. See you at the pre-op on the 17th!", at: hoursAgo(3), state: .delivered),
                ],
                unread: true
            ),
            MessageThread(
                practice: "Midtown Rehab",
                memberName: "Priya Nair, PT",
                memberRole: "Physical therapy · starts post-op",
                mode: .portal,
                category: .admin,
                messages: [
                    CareMessage(author: .team, text: "We'll book your first PT session once surgery is done. Keep up the quad sets — you're walking in strong.", at: hoursAgo(70), state: .delivered),
                ],
                unread: false
            ),
            MessageThread(
                practice: "Walgreens Midtown",
                memberName: "Walgreens Midtown",
                memberRole: "Pharmacy",
                mode: .inApp,
                category: .refill,
                messages: [
                    CareMessage(author: .team, text: "Your post-op pain prescription will be ready for pickup the day of surgery. Acetaminophen is in stock now.", at: hoursAgo(48), state: .delivered),
                ],
                unread: false
            ),
        ]

        let appointments: [Appointment] = [
            Appointment(
                with: "Pre-op visit · Dr. Chen", date: preOp,
                location: "Midtown Orthopedics", prepReady: true,
                kind: .inPerson, status: .confirmed,
                trip: TripPlan(
                    departBy: departBy(preOp, travel: 22, buffer: 20),
                    travelMinutes: 22,
                    routeHint: "22 min drive · morning traffic, leave a cushion",
                    destinationDetail: "Midtown Orthopedics · 5th floor · garage on Peachtree, validated",
                    mapQuery: "Midtown Orthopedics Atlanta",
                    checklist: ["Insurance card", "Full med + supplement list (for anesthesia)", "The NSAID-timing question", "Surgical packet"],
                    rideHint: nil
                ),
                planGoalHint: "Clears you for surgery and confirms the NSAID stop"
            ),
            Appointment(
                with: "Surgery · knee replacement", date: surgery,
                location: "Midtown Surgical Center · arrive 6:30am", prepReady: true,
                kind: .inPerson, status: .confirmed,
                trip: TripPlan(
                    departBy: departBy(surgery, travel: 22, buffer: 40),
                    travelMinutes: 22,
                    routeHint: "22 min drive · pre-dawn, roads clear",
                    destinationDetail: "Midtown Surgical Center · Surgical check-in, 1st floor",
                    mapQuery: "Midtown Surgical Center Atlanta",
                    checklist: ["Nothing to eat after midnight", "ID + insurance card", "Loose shorts, slip-on shoes", "Phone charger", "Ride home confirmed"],
                    calendarConflict: "Heads up — your calendar shows a 5pm work call on the 23rd. You'll still be recovering. Want me to help you move it?",
                    rideHint: "You'll need a driver home from this one — let's make sure that's locked in."
                ),
                planGoalHint: "The main event — walking in strong pays off twice"
            ),
            Appointment(
                with: "Priya Nair, PT · pre-surgery consult", date: ptConsult,
                location: "Telehealth · Midtown Rehab video", prepReady: false,
                kind: .telehealth, status: .pending,
                joinLink: "https://midtownrehab.example/visit/sam",
                trip: TripPlan(
                    departBy: ptConsult,
                    travelMinutes: 0, routeHint: "Join from home",
                    destinationDetail: "Midtown Rehab video visit",
                    mapQuery: "",
                    checklist: ["A clear space to show your range of motion", "Your prehab questions"],
                    isVirtual: true
                ),
                planGoalHint: "Sets up week-one recovery expectations"
            ),
        ]

        let bills: [Bill] = [
            Bill(
                key: "midtown|mri-may14",
                provider: "Midtown Imaging",
                encounter: "Knee MRI · May 14, 2026",
                statementDate: date(2026, 5, 30),
                dueDate: date(2026, 7, 1),
                status: .open,
                amount: 320,
                lineItems: [
                    BillLineItem(label: "MRI, lower extremity", billed: 1600, planPaid: 1280, youOwe: 320, reason: "Applied to deductible"),
                ],
                plainSummary: "This $320 is the MRI that confirmed the surgery — it went toward your deductible, which means less owed on the surgery itself. The math checks out.",
                flag: nil,
                source: "Midtown Imaging statement · May 30"
            ),
        ]

        let cost = CostSummary(
            planName: "UnitedHealthcare · Choice Plus",
            deductibleMet: 1320, deductibleTotal: 2500,
            oopMet: 1640, oopTotal: 5000,
            upcomingEstimate: 1500,
            upcomingLabel: "Knee replacement — estimated your share"
        )

        let documents: [CareDocument] = [
            CareDocument(title: "Insurance card", type: .insuranceCard, capturedAt: date(2026, 5, 2), source: "From your scan", pageCount: 2,
                         fields: [ExtractedField(label: "Member ID", value: "UHC55520198"), ExtractedField(label: "Plan", value: "UHC Choice Plus")], confirmed: true),
            CareDocument(title: "Pre-op instruction sheet", type: .form, capturedAt: date(2026, 6, 2), source: "From your scan",
                         fields: [ExtractedField(label: "Stop NSAIDs", value: "June 16"), ExtractedField(label: "Nothing to eat after", value: "Midnight, June 22")], confirmed: true),
        ]

        let savings: [MedicationSaving] = [
            MedicationSaving(medID: "acetaminophen", kind: .cashPrice, title: "Store-brand acetaminophen", estimateLine: "about $6 — same medicine, lower shelf", basis: "Pharmacy cash-price comparison · informational", sponsor: nil, requiresPII: false),
        ]

        let requests: [CareRequest] = [
            CareRequest(kind: .appointment, subject: "First PT session", detail: "Within a week after surgery", state: .submitted, at: hoursAgo(70), routedTo: "Midtown Rehab (drafted for portal)"),
        ]

        return CareBundle(
            threads: threads,
            appointments: appointments,
            bills: bills,
            cost: cost,
            documents: documents,
            savings: savings,
            requestsSeed: requests,
            resultToAck: ("MRI confirmed — bone-on-bone", "The answer to three years of grinding.", nil),
            lookingAhead: nil   // peri-procedure: keep the focus on the surgery (§4.10)
        )
    }()

    // MARK: - Rosa · cardiometabolic (T2D + heart failure + CKD risk)

    static let rosa: CareBundle = {
        let cardiologyVisit = date(2026, 6, 26, 10, 30)
        let nephTelehealth = date(2026, 7, 2, 14, 0)
        let primaryVisit = date(2026, 7, 9, 9, 30)

        let threads: [MessageThread] = [
            MessageThread(
                practice: "Emory Heart & Vascular",
                memberName: "Dr. Reyes's office",
                memberRole: "Cardiology",
                mode: .inApp,
                category: .medical,
                messages: [
                    CareMessage(author: .user, text: "My weight bumped two pounds after a salty dinner but cleared by morning. Anything to do, or just keep watching?", at: hoursAgo(28), state: .delivered, origin: "From your daily weigh-in"),
                    CareMessage(author: .team, text: "Exactly the right instinct, Rosa — a one-day bump that clears is fine. Keep the morning weigh-ins and call if you're ever up 3 lb overnight. See you the 26th.", at: hoursAgo(5), state: .delivered),
                ],
                unread: true
            ),
            MessageThread(
                practice: "Emory Healthcare",
                memberName: "Dr. Okafor (Nephrology)",
                memberRole: "Kidney care · MyChart",
                mode: .portal,
                category: .medical,
                messages: [
                    CareMessage(author: .team, text: "Your eGFR is holding at 66 — the empagliflozin is doing its protective work. Let's do the telehealth check on July 2 and keep sodium gentle.", at: hoursAgo(54), state: .delivered),
                ],
                unread: false
            ),
            MessageThread(
                practice: "CVS Peachtree",
                memberName: "CVS Peachtree",
                memberRole: "Pharmacy",
                mode: .inApp,
                category: .refill,
                messages: [
                    CareMessage(author: .team, text: "Your empagliflozin is due for refill in 6 days. Want it ready for pickup or switched to delivery? Just reply here.", at: hoursAgo(16), state: .delivered),
                ],
                unread: false
            ),
        ]

        let appointments: [Appointment] = [
            Appointment(
                with: "Dr. Lena Reyes · Cardiology", date: cardiologyVisit,
                location: "Emory Heart & Vascular", prepReady: true,
                kind: .inPerson, status: .confirmed, joinLink: nil,
                trip: TripPlan(
                    departBy: departBy(cardiologyVisit, travel: 20, buffer: 20),
                    travelMinutes: 20,
                    routeHint: "20 min drive · usually light mid-morning",
                    destinationDetail: "Emory Heart & Vascular · 4th floor · deck parking, validated",
                    mapQuery: "Emory Heart and Vascular Atlanta",
                    checklist: ["Insurance card", "Your daily-weight log — I'll have it charted", "Home BP readings", "The furosemide-dose question"],
                    rideHint: nil
                ),
                planGoalHint: "Reviews your weight trend and the fluid plan"
            ),
            Appointment(
                with: "Dr. Samuel Okafor · Nephrology", date: nephTelehealth,
                location: "Telehealth · Emory video visit", prepReady: false,
                kind: .telehealth, status: .confirmed,
                joinLink: "https://emory.example/visit/rosa",
                trip: TripPlan(
                    departBy: nephTelehealth,
                    travelMinutes: 0, routeHint: "Join from home",
                    destinationDetail: "Emory video visit",
                    mapQuery: "",
                    checklist: ["A quiet spot with good signal", "Your latest eGFR question", "The sodium-and-fluid notes"],
                    isVirtual: true
                ),
                planGoalHint: "Checks kidney protection and the eGFR trend"
            ),
            Appointment(
                with: "Dr. Anita Shah · Primary care", date: primaryVisit,
                location: "Piedmont Internal Medicine", prepReady: false,
                kind: .inPerson, status: .pending,
                planGoalHint: "Reconciles all three teams into one plan"
            ),
        ]

        let bills: [Bill] = [
            Bill(
                key: "emory|echo-may",
                provider: "Emory Heart & Vascular",
                encounter: "Echocardiogram · May 12, 2026",
                statementDate: date(2026, 5, 30),
                dueDate: date(2026, 7, 10),
                status: .open,
                amount: 65,
                lineItems: [
                    BillLineItem(label: "Echocardiogram", billed: 540, planPaid: 475, youOwe: 65, reason: "Specialist coinsurance after deductible"),
                    BillLineItem(label: "Cardiology consult", billed: 210, planPaid: 210, youOwe: 0, reason: "Covered in full"),
                ],
                plainSummary: "This is the $65 coinsurance on the echo that confirmed your heart is stable. Insurance covered the rest. Nothing here looks off.",
                flag: nil,
                source: "Emory statement · May 30"
            ),
            Bill(
                key: "quest|mar-labs",
                provider: "Quest Diagnostics",
                encounter: "Kidney + metabolic panel · Mar 14, 2026",
                statementDate: date(2026, 3, 28),
                dueDate: nil,
                status: .paid,
                amount: 0,
                lineItems: [
                    BillLineItem(label: "Comprehensive metabolic panel", billed: 130, planPaid: 130, youOwe: 0, reason: "Preventive — covered in full"),
                ],
                plainSummary: "Fully covered. Here so the record is complete.",
                flag: nil,
                source: "Quest EOB · Mar 28"
            ),
        ]

        let cost = CostSummary(
            planName: "Cigna · PPO",
            deductibleMet: 1200, deductibleTotal: 2000,
            oopMet: 2100, oopTotal: 5000,
            upcomingEstimate: 65,
            upcomingLabel: "June 26 cardiology coinsurance (estimate)"
        )

        let documents: [CareDocument] = [
            CareDocument(title: "Insurance card", type: .insuranceCard, capturedAt: date(2026, 1, 10), source: "From your scan", pageCount: 2,
                         fields: [ExtractedField(label: "Member ID", value: "CIG70432118"), ExtractedField(label: "Plan", value: "Cigna PPO")], confirmed: true),
            CareDocument(title: "Echocardiogram summary", type: .labResult, capturedAt: date(2026, 5, 12), source: "From your scan",
                         fields: [ExtractedField(label: "Ejection fraction", value: "58% · preserved"), ExtractedField(label: "Impression", value: "Stable HFpEF")], confirmed: true),
        ]

        let savings: [MedicationSaving] = [
            MedicationSaving(medID: "empagliflozin", kind: .copayCard, title: "Manufacturer copay card", estimateLine: "as low as $10/month", basis: "Manufacturer program · eligibility independent of sponsorship", sponsor: "Boehringer Ingelheim", requiresPII: true),
            MedicationSaving(medID: "furosemide", kind: .cashPrice, title: "Cash price at CVS Peachtree", estimateLine: "around $4/month for the generic", basis: "Pharmacy cash-price comparison", sponsor: nil, requiresPII: false),
        ]

        let requests: [CareRequest] = [
            CareRequest(kind: .refill, subject: "Empagliflozin 10 mg", detail: "Refill due in 6 days — pickup or delivery", state: .acknowledged, at: hoursAgo(16), routedTo: "CVS Peachtree (in-app)"),
        ]

        return CareBundle(
            threads: threads,
            appointments: appointments,
            bills: bills,
            cost: cost,
            documents: documents,
            savings: savings,
            requestsSeed: requests,
            resultToAck: ("eGFR 66 — holding steady", "Kidneys steady; the protection is working.", "egfr"),
            lookingAhead: LookingAheadNudge(
                headline: "Keeping your three teams in step",
                body: "When diabetes, heart and kidney care overlap, people sometimes benefit from their specialists comparing notes directly. It may be worth asking whether your next eGFR can be reviewed by both cardiology and nephrology.",
                basis: "This is a general suggestion drawn from managing several overlapping conditions — not a prediction about you, and no number or date is implied.",
                guideQuestion: "Can cardiology and nephrology coordinate on my next kidney panel?"
            )
        )
    }()
}
