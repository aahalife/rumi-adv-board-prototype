import { d, hoursAgo, uid } from "./lifeLibrary";
import type { CareBundle, Pathway, MessageThread, Appointment, Bill, CostSummary, CareDocument, MedicationSaving, CareRequest } from "./types";

const departBy = (appt: number, travel: number, buffer: number) => appt - (travel + buffer) * 60000;

const marcus = (): CareBundle => {
  const pattersonVisit = d(2026, 6, 24, 10, 30);
  const nephTelehealth = d(2026, 7, 1, 14, 0);
  const threads: MessageThread[] = [
    { id: uid("th"), practice: "Piedmont Internal Medicine", memberName: "Dr. Patterson's office", memberRole: "Primary care · Privia", mode: "inApp", category: "medical", unread: true, messages: [
      { id: uid("ms"), author: "user", text: "The leg cramps keep landing on nights I take the statin late. Worth changing the timing?", at: hoursAgo(30), state: "delivered", origin: "From the pattern we caught · May 26" },
      { id: uid("ms"), author: "team", text: "Good catch, Marcus — moving atorvastatin to dinnertime is reasonable. Let's confirm it at your June 24 visit and keep logging the cramps until then.", at: hoursAgo(4), state: "delivered" },
    ] },
    { id: uid("th"), practice: "CVS Peachtree", memberName: "CVS Peachtree", memberRole: "Pharmacy", mode: "inApp", category: "refill", unread: false, messages: [
      { id: uid("ms"), author: "team", text: "Your atorvastatin refill is ready for pickup. Want it switched to free delivery? Just reply here.", at: hoursAgo(20), state: "delivered" },
    ] },
    { id: uid("th"), practice: "Emory Healthcare", memberName: "Dr. Okafor (Nephrology)", memberRole: "Kidney care · MyChart", mode: "portal", category: "medical", unread: false, messages: [
      { id: uid("ms"), author: "team", text: "Your March kidney panel looked stable. No changes needed — see you at the telehealth check on July 1.", at: hoursAgo(60), state: "delivered" },
    ] },
  ];
  const appointments: Appointment[] = [
    { id: uid("ap"), with: "Dr. Alicia Patterson", date: pattersonVisit, location: "Piedmont Internal Medicine", prepReady: true, kind: "inPerson", status: "confirmed", joinLink: null, planGoalHint: "Reviews your A1c trend and the home-BP goal",
      trip: { departBy: departBy(pattersonVisit, 18, 20), travelMinutes: 18, routeHint: "18 min drive · usually light mid-morning", destinationDetail: "Piedmont Internal Medicine · 3rd floor, Suite 320 · Lot B parking", mapQuery: "Piedmont Internal Medicine Atlanta", checklist: ["Insurance card", "$42 copay (or Apple Pay on file)", "Home BP cuff readings — I'll have them charted", "The atorvastatin-timing question"], rideHint: "It's a short drive, but I can line up a ride if the truck's acting up." } },
    { id: uid("ap"), with: "Dr. Samuel Okafor · Nephrology", date: nephTelehealth, location: "Telehealth · Emory video visit", prepReady: false, kind: "telehealth", status: "confirmed", joinLink: "https://emory.example/visit/marcus", planGoalHint: "Checks in on kidney protection",
      trip: { departBy: nephTelehealth, travelMinutes: 0, routeHint: "Join from home", destinationDetail: "Emory video visit", mapQuery: "", checklist: ["A quiet spot with good signal", "Your latest home BP readings", "Any questions about the kidney panel"], isVirtual: true } },
  ];
  const bills: Bill[] = [
    { id: uid("bl"), key: "piedmont|mar12-visit", provider: "Piedmont Internal Medicine", encounter: "Office visit · Mar 12, 2026", statementDate: d(2026, 4, 1), dueDate: d(2026, 6, 30), status: "open", amount: 42, plainSummary: "This is the $42 copay from your March visit. Insurance covered the rest, including the labs. Nothing here looks off.", flag: null, source: "Piedmont statement · Apr 1", lineItems: [
      { id: uid("li"), label: "Established patient visit", billed: 186, planPaid: 144, youOwe: 42, reason: "Specialist copay" },
      { id: uid("li"), label: "Metabolic panel", billed: 96, planPaid: 96, youOwe: 0, reason: "Preventive — covered in full" },
    ] },
    { id: uid("bl"), key: "quest|mar12-labs", provider: "Quest Diagnostics", encounter: "Lab draw · Mar 12, 2026", statementDate: d(2026, 3, 28), dueDate: null, status: "paid", amount: 0, plainSummary: "Fully covered. No action needed — it's here so the record is complete.", flag: null, source: "Quest EOB · Mar 28", lineItems: [
      { id: uid("li"), label: "A1c + lipid panel", billed: 120, planPaid: 120, youOwe: 0, reason: "Preventive — covered in full" },
    ] },
  ];
  const cost: CostSummary = { planName: "Anthem Blue · PPO", deductibleMet: 640, deductibleTotal: 1500, oopMet: 980, oopTotal: 4000, upcomingEstimate: 42, upcomingLabel: "June 24 visit copay (estimate)" };
  const documents: CareDocument[] = [
    { id: uid("doc"), title: "Insurance card", type: "insuranceCard", capturedAt: d(2026, 1, 8), source: "From your scan", pageCount: 2, confirmed: true, fields: [{ id: uid("f"), label: "Member ID", value: "ABC123456789" }, { id: uid("f"), label: "Group", value: "PIEDMONT-PPO" }, { id: uid("f"), label: "Plan", value: "Anthem Blue PPO" }] },
    { id: uid("doc"), title: "Eye exam summary", type: "labResult", capturedAt: d(2025, 11, 20), source: "From your scan", confirmed: true, fields: [{ id: uid("f"), label: "Result", value: "Normal · no retinopathy" }, { id: uid("f"), label: "Repeat", value: "Yearly" }] },
  ];
  const savings: MedicationSaving[] = [
    { id: uid("sv"), medID: "atorvastatin", kind: "cashPrice", title: "GoodRx cash price at CVS Peachtree", estimateLine: "about $9/month with the coupon", basis: "Pharmacy cash-price comparison · your CVS", sponsor: null, requiresPII: false },
    { id: uid("sv"), medID: "metformin", kind: "alternative", title: "Already the generic — about as low as it goes", estimateLine: "around $4/month on your plan", basis: "Your formulary tier · informational only", sponsor: null, requiresPII: false },
  ];
  const requestsSeed: CareRequest[] = [{ id: uid("rq"), kind: "refill", subject: "Atorvastatin 20 mg", detail: "Refill ready — pickup or delivery", state: "acknowledged", at: hoursAgo(20), routedTo: "CVS Peachtree (in-app)" }];
  return { threads, appointments, bills, cost, documents, savings, requestsSeed,
    resultToAck: { title: "A1c — 8.4%", detail: "Down from 8.7 in December — fifth drop in a row.", series: "a1c" },
    lookingAhead: { headline: "A screening worth a conversation", body: "People managing diabetes for several years sometimes benefit from a kidney-protection medication review. It may be worth asking Dr. Patterson whether it fits you.", basis: "This is a general, population-level suggestion based on living with type 2 diabetes — not a prediction about you, and no number or date is implied.", guideQuestion: "Is there a kidney-protective medication (like an SGLT2) worth considering for me?" } };
};

const elena = (): CareBundle => {
  const cycle4 = d(2026, 6, 22, 9, 0);
  const riveraVisit = d(2026, 7, 6, 11, 0);
  const navigatorCheck = d(2026, 6, 18, 15, 0);
  const threads: MessageThread[] = [
    { id: uid("th"), practice: "Northside Cancer Institute", memberName: "Dr. Rivera's team", memberRole: "Oncology", mode: "inApp", category: "medical", unread: true, messages: [
      { id: uid("ms"), author: "user", text: "Cycle 3 went so much better with the scheduled ondansetron. Can we keep the same plan for cycle 4?", at: hoursAgo(40), state: "delivered", origin: "Added after cycle 3 went smoothly" },
      { id: uid("ms"), author: "team", text: "Absolutely — we'll keep the same anti-nausea schedule. I've noted it for cycle 4 on the 22nd. Proud of how you're navigating this, Elena.", at: hoursAgo(6), state: "delivered" },
    ] },
    { id: uid("th"), practice: "Northside Cancer Institute", memberName: "Nia Coleman, RN", memberRole: "Infusion nurse navigator", mode: "inApp", category: "medical", unread: false, messages: [
      { id: uid("ms"), author: "team", text: "Reminder: your low-count window opens around day 7. Keep the thermometer close — 100.4\u00B0F or higher is a call-us-now, any hour.", at: hoursAgo(18), state: "delivered" },
    ] },
    { id: uid("th"), practice: "Northside Pharmacy", memberName: "Northside Pharmacy", memberRole: "Pharmacy", mode: "inApp", category: "refill", unread: false, messages: [
      { id: uid("ms"), author: "team", text: "Your ondansetron and dexamethasone are stocked and ready ahead of cycle 4. No action needed.", at: hoursAgo(50), state: "delivered" },
    ] },
  ];
  const appointments: Appointment[] = [
    { id: uid("ap"), with: "Cycle 4 infusion · Dr. Rivera's team", date: cycle4, location: "Northside Infusion Center", prepReady: true, kind: "inPerson", status: "confirmed", planGoalHint: "Cycle 4 of 6 — anti-nausea plan carried over from cycle 3",
      trip: { departBy: departBy(cycle4, 25, 30), travelMinutes: 25, routeHint: "25 min drive · leave a buffer, infusion days run long", destinationDetail: "Northside Infusion Center · 2nd floor · valet available at the main entrance", mapQuery: "Northside Infusion Center Atlanta", checklist: ["Insurance card", "A warm layer — infusion rooms run cold", "Something to pass the time (3–4 hrs)", "Pre-meds taken this morning", "A driver for the way home"], rideHint: "You shouldn't drive yourself home after infusion — want me to help arrange a ride?" } },
    { id: uid("ap"), with: "Nia Coleman, RN · symptom check", date: navigatorCheck, location: "Telehealth · Northside video visit", prepReady: false, kind: "telehealth", status: "confirmed", joinLink: "https://northside.example/visit/elena", planGoalHint: "Checks the low-count window plan with you",
      trip: { departBy: navigatorCheck, travelMinutes: 0, routeHint: "Join from home", destinationDetail: "Northside video visit", mapQuery: "", checklist: ["Your symptom log this cycle", "The tingling notes since cycle 2", "A quiet, well-lit spot"], isVirtual: true } },
    { id: uid("ap"), with: "Dr. Maya Rivera", date: riveraVisit, location: "Northside Cancer Institute", prepReady: false, kind: "inPerson", status: "confirmed", planGoalHint: "Mid-treatment review" },
  ];
  const bills: Bill[] = [
    { id: uid("bl"), key: "northside|cycle2-infusion", provider: "Northside Cancer Institute", encounter: "Cycle 2 infusion · Apr 20, 2026", statementDate: d(2026, 5, 10), dueDate: d(2026, 7, 15), status: "open", amount: 180, plainSummary: "Most of this is covered. Your share is the $180 coinsurance on the infusion. There's no rush — the due date is in July, and financial counseling at Northside can set up a payment plan if that helps.", flag: null, source: "Northside statement · May 10", lineItems: [
      { id: uid("li"), label: "Chemotherapy administration", billed: 4200, planPaid: 4020, youOwe: 180, reason: "20% coinsurance after deductible" },
      { id: uid("li"), label: "Anti-nausea medications", billed: 320, planPaid: 320, youOwe: 0, reason: "Covered in full" },
    ] },
    { id: uid("bl"), key: "northside|cycle1-infusion", provider: "Northside Cancer Institute", encounter: "Cycle 1 infusion · Feb 16, 2026", statementDate: d(2026, 3, 8), dueDate: null, status: "paid", amount: 0, plainSummary: "This one's settled. It's also the bill that met your deductible for the year, which is why your share dropped after it.", flag: null, source: "Northside EOB · Mar 8", lineItems: [
      { id: uid("li"), label: "Chemotherapy administration", billed: 4200, planPaid: 4200, youOwe: 0, reason: "Applied to deductible — now met" },
    ] },
  ];
  const cost: CostSummary = { planName: "Aetna · Choice POS II", deductibleMet: 2000, deductibleTotal: 2000, oopMet: 3600, oopTotal: 6000, upcomingEstimate: 180, upcomingLabel: "Cycle 4 coinsurance (estimate)" };
  const documents: CareDocument[] = [
    { id: uid("doc"), title: "Insurance card", type: "insuranceCard", capturedAt: d(2026, 2, 1), source: "From your scan", pageCount: 2, confirmed: true, fields: [{ id: uid("f"), label: "Member ID", value: "AET88810231" }, { id: uid("f"), label: "Plan", value: "Aetna Choice POS II" }] },
    { id: uid("doc"), title: "Chemo schedule handout", type: "form", capturedAt: d(2026, 2, 14), source: "From your scan", confirmed: true, fields: [{ id: uid("f"), label: "Regimen", value: "AC-T · 6 cycles" }, { id: uid("f"), label: "Cadence", value: "Every 3 weeks" }] },
  ];
  const savings: MedicationSaving[] = [
    { id: uid("sv"), medID: "ondansetron", kind: "copayCard", title: "Manufacturer copay card", estimateLine: "about $25/month less", basis: "Manufacturer program · eligibility independent of sponsorship", sponsor: "Helsinn", requiresPII: true },
    { id: uid("sv"), medID: "ondansetron", kind: "cashPrice", title: "Cash price at Northside Pharmacy", estimateLine: "around $12 for the generic", basis: "Pharmacy cash-price comparison", sponsor: null, requiresPII: false },
  ];
  const requestsSeed: CareRequest[] = [{ id: uid("rq"), kind: "form", subject: "FMLA paperwork", detail: "Treatment dates letter for employer", state: "submitted", at: hoursAgo(72), routedTo: "Dr. Rivera's office (in-app)" }];
  return { threads, appointments, bills, cost, documents, savings, requestsSeed,
    resultToAck: { title: "Counts recovered — ANC 1.7", detail: "Right on time, third cycle running.", series: "anc" }, lookingAhead: null };
};

const sam = (): CareBundle => {
  const preOp = d(2026, 6, 17, 9, 0);
  const surgery = d(2026, 6, 23, 6, 30);
  const ptConsult = d(2026, 6, 19, 13, 0);
  const threads: MessageThread[] = [
    { id: uid("th"), practice: "Midtown Orthopedics", memberName: "Dr. Chen's office", memberRole: "Orthopedic surgery", mode: "inApp", category: "medical", unread: true, messages: [
      { id: uid("ms"), author: "user", text: "Just to be sure — do I stop the ibuprofen the morning of the 16th or the night before?", at: hoursAgo(26), state: "delivered", origin: "From the NSAID heads-up · Jun 11" },
      { id: uid("ms"), author: "team", text: "Stop after your last dose on the 15th — so none on the 16th onward. Acetaminophen is fine right up to surgery. See you at the pre-op on the 17th!", at: hoursAgo(3), state: "delivered" },
    ] },
    { id: uid("th"), practice: "Midtown Rehab", memberName: "Priya Nair, PT", memberRole: "Physical therapy · starts post-op", mode: "portal", category: "admin", unread: false, messages: [
      { id: uid("ms"), author: "team", text: "We'll book your first PT session once surgery is done. Keep up the quad sets — you're walking in strong.", at: hoursAgo(70), state: "delivered" },
    ] },
    { id: uid("th"), practice: "Walgreens Midtown", memberName: "Walgreens Midtown", memberRole: "Pharmacy", mode: "inApp", category: "refill", unread: false, messages: [
      { id: uid("ms"), author: "team", text: "Your post-op pain prescription will be ready for pickup the day of surgery. Acetaminophen is in stock now.", at: hoursAgo(48), state: "delivered" },
    ] },
  ];
  const appointments: Appointment[] = [
    { id: uid("ap"), with: "Pre-op visit · Dr. Chen", date: preOp, location: "Midtown Orthopedics", prepReady: true, kind: "inPerson", status: "confirmed", planGoalHint: "Clears you for surgery and confirms the NSAID stop",
      trip: { departBy: departBy(preOp, 22, 20), travelMinutes: 22, routeHint: "22 min drive · morning traffic, leave a cushion", destinationDetail: "Midtown Orthopedics · 5th floor · garage on Peachtree, validated", mapQuery: "Midtown Orthopedics Atlanta", checklist: ["Insurance card", "Full med + supplement list (for anesthesia)", "The NSAID-timing question", "Surgical packet"], rideHint: null } },
    { id: uid("ap"), with: "Surgery · knee replacement", date: surgery, location: "Midtown Surgical Center · arrive 6:30am", prepReady: true, kind: "inPerson", status: "confirmed", planGoalHint: "The main event — walking in strong pays off twice",
      trip: { departBy: departBy(surgery, 22, 40), travelMinutes: 22, routeHint: "22 min drive · pre-dawn, roads clear", destinationDetail: "Midtown Surgical Center · Surgical check-in, 1st floor", mapQuery: "Midtown Surgical Center Atlanta", checklist: ["Nothing to eat after midnight", "ID + insurance card", "Loose shorts, slip-on shoes", "Phone charger", "Ride home confirmed"], calendarConflict: "Heads up — your calendar shows a 5pm work call on the 23rd. You'll still be recovering. Want me to help you move it?", rideHint: "You'll need a driver home from this one — let's make sure that's locked in." } },
    { id: uid("ap"), with: "Priya Nair, PT · pre-surgery consult", date: ptConsult, location: "Telehealth · Midtown Rehab video", prepReady: false, kind: "telehealth", status: "pending", joinLink: "https://midtownrehab.example/visit/sam", planGoalHint: "Sets up week-one recovery expectations",
      trip: { departBy: ptConsult, travelMinutes: 0, routeHint: "Join from home", destinationDetail: "Midtown Rehab video visit", mapQuery: "", checklist: ["A clear space to show your range of motion", "Your prehab questions"], isVirtual: true } },
  ];
  const bills: Bill[] = [
    { id: uid("bl"), key: "midtown|mri-may14", provider: "Midtown Imaging", encounter: "Knee MRI · May 14, 2026", statementDate: d(2026, 5, 30), dueDate: d(2026, 7, 1), status: "open", amount: 320, plainSummary: "This $320 is the MRI that confirmed the surgery — it went toward your deductible, which means less owed on the surgery itself. The math checks out.", flag: null, source: "Midtown Imaging statement · May 30", lineItems: [
      { id: uid("li"), label: "MRI, lower extremity", billed: 1600, planPaid: 1280, youOwe: 320, reason: "Applied to deductible" },
    ] },
  ];
  const cost: CostSummary = { planName: "UnitedHealthcare · Choice Plus", deductibleMet: 1320, deductibleTotal: 2500, oopMet: 1640, oopTotal: 5000, upcomingEstimate: 1500, upcomingLabel: "Knee replacement — estimated your share" };
  const documents: CareDocument[] = [
    { id: uid("doc"), title: "Insurance card", type: "insuranceCard", capturedAt: d(2026, 5, 2), source: "From your scan", pageCount: 2, confirmed: true, fields: [{ id: uid("f"), label: "Member ID", value: "UHC55520198" }, { id: uid("f"), label: "Plan", value: "UHC Choice Plus" }] },
    { id: uid("doc"), title: "Pre-op instruction sheet", type: "form", capturedAt: d(2026, 6, 2), source: "From your scan", confirmed: true, fields: [{ id: uid("f"), label: "Stop NSAIDs", value: "June 16" }, { id: uid("f"), label: "Nothing to eat after", value: "Midnight, June 22" }] },
  ];
  const savings: MedicationSaving[] = [
    { id: uid("sv"), medID: "acetaminophen", kind: "cashPrice", title: "Store-brand acetaminophen", estimateLine: "about $6 — same medicine, lower shelf", basis: "Pharmacy cash-price comparison · informational", sponsor: null, requiresPII: false },
  ];
  const requestsSeed: CareRequest[] = [{ id: uid("rq"), kind: "appointment", subject: "First PT session", detail: "Within a week after surgery", state: "submitted", at: hoursAgo(70), routedTo: "Midtown Rehab (drafted for portal)" }];
  return { threads, appointments, bills, cost, documents, savings, requestsSeed,
    resultToAck: { title: "MRI confirmed — bone-on-bone", detail: "The answer to three years of grinding.", series: null }, lookingAhead: null };
};

const rosa = (): CareBundle => {
  const cardiologyVisit = d(2026, 6, 26, 10, 30);
  const nephTelehealth = d(2026, 7, 2, 14, 0);
  const primaryVisit = d(2026, 7, 9, 9, 30);
  const threads: MessageThread[] = [
    { id: uid("th"), practice: "Emory Heart & Vascular", memberName: "Dr. Reyes's office", memberRole: "Cardiology", mode: "inApp", category: "medical", unread: true, messages: [
      { id: uid("ms"), author: "user", text: "My weight bumped two pounds after a salty dinner but cleared by morning. Anything to do, or just keep watching?", at: hoursAgo(28), state: "delivered", origin: "From your daily weigh-in" },
      { id: uid("ms"), author: "team", text: "Exactly the right instinct, Rosa — a one-day bump that clears is fine. Keep the morning weigh-ins and call if you're ever up 3 lb overnight. See you the 26th.", at: hoursAgo(5), state: "delivered" },
    ] },
    { id: uid("th"), practice: "Emory Healthcare", memberName: "Dr. Okafor (Nephrology)", memberRole: "Kidney care · MyChart", mode: "portal", category: "medical", unread: false, messages: [
      { id: uid("ms"), author: "team", text: "Your eGFR is holding at 66 — the empagliflozin is doing its protective work. Let's do the telehealth check on July 2 and keep sodium gentle.", at: hoursAgo(54), state: "delivered" },
    ] },
    { id: uid("th"), practice: "CVS Peachtree", memberName: "CVS Peachtree", memberRole: "Pharmacy", mode: "inApp", category: "refill", unread: false, messages: [
      { id: uid("ms"), author: "team", text: "Your empagliflozin is due for refill in 6 days. Want it ready for pickup or switched to delivery? Just reply here.", at: hoursAgo(16), state: "delivered" },
    ] },
  ];
  const appointments: Appointment[] = [
    { id: uid("ap"), with: "Dr. Lena Reyes · Cardiology", date: cardiologyVisit, location: "Emory Heart & Vascular", prepReady: true, kind: "inPerson", status: "confirmed", joinLink: null, planGoalHint: "Reviews your weight trend and the fluid plan",
      trip: { departBy: departBy(cardiologyVisit, 20, 20), travelMinutes: 20, routeHint: "20 min drive · usually light mid-morning", destinationDetail: "Emory Heart & Vascular · 4th floor · deck parking, validated", mapQuery: "Emory Heart and Vascular Atlanta", checklist: ["Insurance card", "Your daily-weight log — I'll have it charted", "Home BP readings", "The furosemide-dose question"], rideHint: null } },
    { id: uid("ap"), with: "Dr. Samuel Okafor · Nephrology", date: nephTelehealth, location: "Telehealth · Emory video visit", prepReady: false, kind: "telehealth", status: "confirmed", joinLink: "https://emory.example/visit/rosa", planGoalHint: "Checks kidney protection and the eGFR trend",
      trip: { departBy: nephTelehealth, travelMinutes: 0, routeHint: "Join from home", destinationDetail: "Emory video visit", mapQuery: "", checklist: ["A quiet spot with good signal", "Your latest eGFR question", "The sodium-and-fluid notes"], isVirtual: true } },
    { id: uid("ap"), with: "Dr. Anita Shah · Primary care", date: primaryVisit, location: "Piedmont Internal Medicine", prepReady: false, kind: "inPerson", status: "pending", planGoalHint: "Reconciles all three teams into one plan" },
  ];
  const bills: Bill[] = [
    { id: uid("bl"), key: "emory|echo-may", provider: "Emory Heart & Vascular", encounter: "Echocardiogram · May 12, 2026", statementDate: d(2026, 5, 30), dueDate: d(2026, 7, 10), status: "open", amount: 65, plainSummary: "This is the $65 coinsurance on the echo that confirmed your heart is stable. Insurance covered the rest. Nothing here looks off.", flag: null, source: "Emory statement · May 30", lineItems: [
      { id: uid("li"), label: "Echocardiogram", billed: 540, planPaid: 475, youOwe: 65, reason: "Specialist coinsurance after deductible" },
      { id: uid("li"), label: "Cardiology consult", billed: 210, planPaid: 210, youOwe: 0, reason: "Covered in full" },
    ] },
    { id: uid("bl"), key: "quest|mar-labs", provider: "Quest Diagnostics", encounter: "Kidney + metabolic panel · Mar 14, 2026", statementDate: d(2026, 3, 28), dueDate: null, status: "paid", amount: 0, plainSummary: "Fully covered. Here so the record is complete.", flag: null, source: "Quest EOB · Mar 28", lineItems: [
      { id: uid("li"), label: "Comprehensive metabolic panel", billed: 130, planPaid: 130, youOwe: 0, reason: "Preventive — covered in full" },
    ] },
  ];
  const cost: CostSummary = { planName: "Cigna · PPO", deductibleMet: 1200, deductibleTotal: 2000, oopMet: 2100, oopTotal: 5000, upcomingEstimate: 65, upcomingLabel: "June 26 cardiology coinsurance (estimate)" };
  const documents: CareDocument[] = [
    { id: uid("doc"), title: "Insurance card", type: "insuranceCard", capturedAt: d(2026, 1, 10), source: "From your scan", pageCount: 2, confirmed: true, fields: [{ id: uid("f"), label: "Member ID", value: "CIG70432118" }, { id: uid("f"), label: "Plan", value: "Cigna PPO" }] },
    { id: uid("doc"), title: "Echocardiogram summary", type: "labResult", capturedAt: d(2026, 5, 12), source: "From your scan", confirmed: true, fields: [{ id: uid("f"), label: "Ejection fraction", value: "58% · preserved" }, { id: uid("f"), label: "Impression", value: "Stable HFpEF" }] },
  ];
  const savings: MedicationSaving[] = [
    { id: uid("sv"), medID: "empagliflozin", kind: "copayCard", title: "Manufacturer copay card", estimateLine: "as low as $10/month", basis: "Manufacturer program · eligibility independent of sponsorship", sponsor: "Boehringer Ingelheim", requiresPII: true },
    { id: uid("sv"), medID: "furosemide", kind: "cashPrice", title: "Cash price at CVS Peachtree", estimateLine: "around $4/month for the generic", basis: "Pharmacy cash-price comparison", sponsor: null, requiresPII: false },
  ];
  const requestsSeed: CareRequest[] = [{ id: uid("rq"), kind: "refill", subject: "Empagliflozin 10 mg", detail: "Refill due in 6 days — pickup or delivery", state: "acknowledged", at: hoursAgo(16), routedTo: "CVS Peachtree (in-app)" }];
  return { threads, appointments, bills, cost, documents, savings, requestsSeed,
    resultToAck: { title: "eGFR 66 — holding steady", detail: "Kidneys steady; the protection is working.", series: "egfr" },
    lookingAhead: { headline: "Keeping your three teams in step", body: "When diabetes, heart and kidney care overlap, people sometimes benefit from their specialists comparing notes directly. It may be worth asking whether your next eGFR can be reviewed by both cardiology and nephrology.", basis: "This is a general suggestion drawn from managing several overlapping conditions — not a prediction about you, and no number or date is implied.", guideQuestion: "Can cardiology and nephrology coordinate on my next kidney panel?" } };
};

export function careBundleFor(pathway: Pathway): CareBundle {
  if (pathway === "metabolic") return marcus();
  if (pathway === "oncology") return elena();
  if (pathway === "cardiometabolic") return rosa();
  return sam();
}

// ---- Symptom support plans (the L5 brain, fixture-scripted) ----
import type { SupportPlan } from "./types";

export function supportPlan(pathway: Pathway, kind: string, severity: number): SupportPlan {
  const high = severity >= 0.65;
  const name = pathway === "metabolic" ? "Marcus" : pathway === "oncology" ? "Elena" : pathway === "cardiometabolic" ? "Rosa" : "Sam";
  if (pathway === "oncology") {
    if (kind === "Fever or chills") return { message: "Fever during chemo is the one symptom we never sit on. If the thermometer reads 100.4\u00B0F or higher, call Dr. Rivera's team now — any hour. They expect these calls; it's what the on-call line is for.", tips: ["Take your temperature now if you haven't — the number decides everything", "100.4\u00B0F or higher \u2192 call immediately, even at 3am", "Under 100.4 \u2192 recheck in an hour, rest, fluids, and log it"], urgent: true, guideQuestion: "Fever episode this cycle — does my threshold or plan change for cycle 4?", draftMessage: "Elena logged fever/chills (cycle 3, day 6). Temperature reading and timing attached. Please advise." };
    if (kind === "Nausea") return { message: high ? "Breakthrough nausea this strong means the plan needs reinforcements — not that you need more grit. The team has stronger options; they just need to hear it's breaking through." : "Logged. Day-by-day nausea is cycle 3 doing its thing — your scheduled ondansetron is still the best tool, taken on time rather than after.", tips: ["Cold food, small portions — smell is half the battle", "Next ondansetron on schedule, not when it gets bad", "Sips count: ice chips, ginger tea, watered juice"], urgent: high, guideQuestion: high ? "Nausea broke through the schedule — can we add a second-line anti-nausea med?" : "Nausea pattern this cycle — any tweaks for cycle 4?", draftMessage: `Elena is logging ${high ? "breakthrough" : "manageable"} nausea on her scheduled regimen (cycle 3).` };
    if (kind === "Tingling hands/feet") return { message: "Logged with its place on the map. Tingling in hands or feet during taxane cycles is exactly the thing Dr. Rivera asks about — it's how dosing decisions get made, so every log here genuinely matters.", tips: ["Note when it's strongest — morning, evening, after cold", "Mention buttons, jar lids, or dropped keys — function details help the team", "Keep hands and feet warm; cold makes it louder"], urgent: high, guideQuestion: high ? "Tingling is interfering with daily things — does the cycle 4 dose need adjusting?" : "Tingling comes and goes — does the cycle 4 dose need adjusting?", draftMessage: "Elena is logging tingling in hands/feet. Location log attached for neuropathy review before cycle 4." };
    return { message: high ? "That's a hard one, and you didn't carry it alone — it's logged, and the team can hear about it today if you want." : "Logged, gently. Treatment weeks hold a lot; naming it is part of getting through it.", tips: ["Nothing needs solving this minute", "If it's still loud tomorrow, we tell the team together — one tap"], urgent: high, guideQuestion: `${kind} during cycle 3 — normal course, or worth a closer look?`, draftMessage: `Elena logged ${kind.toLowerCase()} during cycle 3 and wanted the care team aware.` };
  }
  if (pathway === "procedure") {
    if (kind === "Knee pain") return { message: high ? "A hard pain day twelve days out — frustrating, but it changes nothing about the plan. Acetaminophen is your green-lit option; the ibuprofen shortcut is the one we can't take this close." : "Logged with its spot on the map. Pain that wobbles day to day is the knee being itself — your trend is still two points better on prehab days.", tips: ["Acetaminophen is surgery-safe — ibuprofen is not, from June 16", "Ice 15 minutes after today's walk", "Shorter walk today beats no walk"], urgent: false, guideQuestion: high ? "Bad pain days before surgery — anything stronger that's still pre-op safe?" : "Pain trend before surgery — on track?", draftMessage: "Sam logged knee pain ahead of the June 23 surgery. Trend attached for the pre-op visit." };
    if (kind === "Swelling") return { message: high ? "Notable swelling close to surgery is worth a quick call to Dr. Chen's office today — usually it's nothing, but pre-op is when they want to know." : "Logged with location. Elevation and ice tonight; the pre-op visit Tuesday can take a look.", tips: ["Elevate the knee above the heart for 20 minutes", "Ice, then a gentle few steps", "Keep logging — pre-op baseline matters"], urgent: high, guideQuestion: "Swelling before surgery — anything to do differently this week?", draftMessage: `Sam logged ${high ? "notable" : "mild"} knee swelling before the June 23 surgery.` };
    return { message: high ? "That sounds rough this close to surgery — it's logged, and we can loop in Dr. Chen's office today if you want." : "Logged. The countdown holds a lot; one foot in front of the other.", tips: ["Rest counts as prehab too", "If it sharpens, log it again — pre-op baselines matter"], urgent: high, guideQuestion: `${kind} before surgery — anything worth flagging at the pre-op?`, draftMessage: `Sam logged ${kind.toLowerCase()} before surgery and wanted the office aware.` };
  }
  if (pathway === "cardiometabolic") {
    if (kind === "Shortness of breath") return { message: high ? "Breathlessness like this with your heart is the one we don't sit on. If it's new, worse lying flat, or comes with a fast weight jump, call Dr. Reyes's team now — any hour. That's exactly what the line is for." : "Logged, and I'm watching it with your heart in mind. A little breathlessness on exertion can be ordinary — but paired with the scale climbing, it's the early sign we act on together.", tips: ["Check your weight now — a jump alongside this is the call-worthy combination", "Can you lie flat comfortably tonight? If not, that's worth telling the team", "Sit upright, slow the breath; log how many blocks or stairs brought it on"], urgent: high, guideQuestion: `Shortness of breath ${high ? "that's new or worse" : "on exertion"} — does my fluid plan or furosemide need a look?`, draftMessage: `Rosa logged ${high ? "significant" : "mild"} shortness of breath. Today's weight and recent trend attached for the heart team — please advise.` };
    if (kind === "Weight jump" || kind === "Swelling") return { message: high ? "A real jump on the scale or swelling that's climbing is fluid — and with your heart, that's a same-day call to Dr. Reyes's office, not a wait. Caught today, it's a phone fix." : "Logged with care. A small bump that clears by morning is usually a salty meal; one that holds two days running is the fluid signal we tell the team about.", tips: ["Weigh again tomorrow, same time — the trend decides everything", "Go light on salt today; check both ankles for one-sided swelling", "If you're up 3 lb overnight or 5 in a week, that's the call line"], urgent: high, guideQuestion: "Fluid showing on the scale — should furosemide flex on heavy days?", draftMessage: `Rosa logged ${high ? "a notable" : "a small"} weight/fluid change. Daily-weight trend attached for Dr. Reyes — does the diuretic plan need adjusting?` };
    if (kind === "Dizziness") return { message: high ? "Strong dizziness deserves attention with your heart meds in the mix — lisinopril and furosemide can pull pressure or fluid a touch low. Worth a same-day call so we get the balance right." : "Noted, and held against your meds. Standing up slowly helps; if it pairs with a low weight or strong thirst, the furosemide may have done a little too much.", tips: ["Stand in two stages today — edge of the bed, then up", "Check your weight and a BP reading; I'll fold them in", "Sip water through the day unless the team has capped your fluids"], urgent: high, guideQuestion: `Dizzy spells${high ? " (strong ones)" : ""} — could the furosemide or lisinopril dose be part of it?`, draftMessage: `Rosa logged ${high ? "significant" : "mild"} dizziness. Recent weight and BP attached — could the diuretic/ACE balance be reviewed?` };
    return { message: high ? "That sounds genuinely rough, and it's logged where it counts. With three things in the room, one extra call beats one too few — I can set it up in a tap." : "Got it — logged and woven in across your heart, sugar and kidney picture. If a pattern forms, you'll hear it from me first.", tips: ["Nothing to fix tonight — rest is allowed to be the whole plan", "If it shifts or sharpens, log it again; trends beat memories"], urgent: high, guideQuestion: `${kind} — ${high ? "hit hard recently" : "showing up sometimes"}; worth discussing?`, draftMessage: `Rosa logged ${kind.toLowerCase()} (${high ? "significant" : "mild"}) today and wanted the office to be aware.` };
  }
  // metabolic
  if (kind === "Dizziness") return { message: high ? "That's a lot of dizziness, and I don't want to shrug at it. With lisinopril in the picture, strong dizzy spells are worth a same-day call — it can mean your dose is working harder than it needs to." : "Noted. Dizziness with your meds is usually about standing up fast, a light breakfast, or a low-water shift — but it's worth keeping an eye on together.", tips: ["Sit or stand up in two stages for the next day — bed, edge, then up", "Check your BP and a glucose reading if you can; I'll fold them in", "Water first, coffee second on warehouse mornings"], urgent: high, guideQuestion: `Dizzy spells${high ? " (strong ones)" : ""} — could lisinopril dosing be part of it?`, draftMessage: `Marcus logged ${high ? "significant" : "mild"} dizziness today. Home BP and meds list attached.` };
  if (kind === "Leg cramps") return { message: "Logged — and it fits the pattern we've been watching: cramps cluster on nights the statin drifts late. Four of five times now.", tips: ["Gentle calf stretch before bed tonight", "Water through the evening — cramps love a dry day", "Note tonight's statin time; the pattern gets sharper with each log"], urgent: false, guideQuestion: "Leg cramps keep clustering on late-statin nights — worth a timing change?", draftMessage: "Marcus has logged recurring leg cramps that cluster on late atorvastatin doses (4 of 5 instances)." };
  if (kind === "Foot tingling") return { message: high ? "Strong tingling in the feet deserves real attention with your diabetes — not panic, attention. Let's get it in front of Dr. Patterson properly." : "Logged, with its place on the map. Tingling that comes and goes is common; the pattern over weeks is what we watch.", tips: ["A quick look at both feet tonight — any new marks or pressure spots", "Comfortable shoes on shift days this week", "Log it again when it happens; location + timing builds the picture"], urgent: high, guideQuestion: `Foot tingling ${high ? "getting stronger" : "on and off"} — time for a sensation check?`, draftMessage: `Marcus logged ${high ? "significant" : "intermittent"} foot tingling. Given his T2D, could a foot sensation check be added?` };
  return { message: high ? "That sounds genuinely rough, and it's logged where it counts. If this keeps its grip through tomorrow, the office should hear about it — I can set that up in one tap." : "Got it — logged and woven in. If a pattern forms, you'll hear it from me first.", tips: ["Nothing to fix tonight — rest is allowed to be the whole plan", "If it shifts or sharpens, log it again; trends beat memories"], urgent: high, guideQuestion: `${kind} — ${high ? "hit hard recently" : "showing up sometimes"}; worth discussing?`, draftMessage: `${name} logged ${kind.toLowerCase()} (${high ? "significant" : "mild"}) today and wanted the office to be aware.` };
}
