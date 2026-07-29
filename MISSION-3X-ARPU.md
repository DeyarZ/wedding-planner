# Mission 3x ARPU — Wedding Planner (BridePlan)

**Stand:** 2026-07-29 · **Baseline:** $0.62 RPD (Revenue per Download) · **Ziel:** $1.50–2.00 · **Deadline-Constraint:** Alles muss vor Dezember live + validiert sein (Verlobungs-Season Dez–Feb = der Install-Cohort des Jahres).

Grundlage: Codebase-Audit + 2 Deep-Research-Dossiers (RevenueCat SOSA 2026, Adapty SOIS 2026, Superwall 40M+ Paywall-Opens, 20+ App-Teardowns, Live-IAP-Daten von ~40 Wedding-Apps).

---

## Die eine Wahrheit

$0.62 ist exakt der Lifestyle-Median (Adapty: $0.70). Die App ist nicht kaputt — sie ist **durchschnittlich**, und die Top 10% der Lifestyle-Apps kassieren 97,9% des Kategorie-Umsatzes. Der Hebel ist **nicht** Paywall-Kosmetik (Visual/Copy-Tests gewinnen nur 34,6%), sondern **Preis-Tier + Gate + Plan-Mix**:

- Preis-Tier: High-priced Apps = **$62.19** Year-1-LTV/Payer vs. Low-priced **$10.69** (5,8x) — und sie konvertieren BESSER (8,9% vs 4,4% Install→Trial).
- Gate: Hard Paywall = **$3.09** RPI D60 vs. Freemium **$0.38** (8x) — bei identischer 12-Monats-Payer-Retention (27% vs 28%).
- Wir sind mit $7.99 Weekly / $29.99 6-Monate **unter jedem ernsthaften Indie-Wettbewerber** (Marktband: $39.99–49.99 Annual + $19.99–149 Lifetime; Wedplan DE probt €249.99 one-time).

**Wedding-Spezifikum:** Hochzeit = endlicher Use-Case (~15 Monate Engagement, The Knot 2026, n=10.474). Es gibt kein Jahr 2 → **die erste Zahlung IST der LTV**. Front-loaden ohne schlechtes Gewissen: Annual-Default + One-Time "Forever". Weekly ist in Lifestyle die schlechteste Duration (LTV ~$22 vs Annual ~$45) → nur noch Rescue-SKU.

**Erwartungsrechnung (konservativ):**
```
$0.62  Baseline
×1.8   härteres Gate + Paywall-Placement          → $1.12
×1.4   Preis-Tier low → mid ($49.99 Annual)       → $1.57
×1.06  Forever-Upsell (~10% Take)                 → $1.66
×1.12  Dismissal-Ladder + Winback                 → $1.86  ✅ im Zielband
```

---

## Phase 0 — Blutende Wunden + Instrumentierung (Woche 1)

Bugs, die JETZT Geld kosten. Kein Redesign nötig.

| # | Fix | Datei | Warum |
|---|---|---|---|
| 0.1 | **Nicht-USD-Preis-Bug**: `calculateWeeklyPrice()` parst nur `$`-Preise; jede EUR/GBP-Locale sieht hardcoded **"$1.15/week"** auf der 6-Monats-Card — falscher Preis, falsche Währung | `PaywallView.swift:257` | Direkt conversion-schädlich für alle Nicht-US-User. RC `StoreProduct.pricePerWeek` + `priceFormatter` nutzen |
| 0.2 | **Notification-Prompt aus `App.init()` entfernen** — feuert ungeprimed vor dem ersten Frame, verbrennt den One-Shot-iOS-Prompt und entwertet beide Priming-Screens | `weddingplannerApp.swift:24` | Custom-Primer vor System-Dialog = +10–25% Opt-in (Airship) |
| 0.3 | **Review-Prompt raus aus Onboarding** (Screen 8, einziger Button "Sure!") → nach echtem Win-Moment (10 Tasks erledigt / Budget angelegt) | `OnboardingView.swift:3138` | Apple rejected das inzwischen aktiv (Guideline 5.6.3) — Rejection-Risiko |
| 0.4 | **Trial-Inkonsistenz**: Paywall sagt 3 Tage, `TrialNotificationManager` plant Reminder für 7-Tage-Trial (Tag 5/6) | `OnboardingView.swift:1352` | Trust-Killer + falsche Reminder |
| 0.5 | **`NotificationManager.scheduleDefaultNotifications()` löscht die Trial-Reminder wieder** (`removeAllPendingNotificationRequests`) | `NotificationManager.swift:42` | Trial-End-Reminder = Conversion-Asset (+6,4% Trial, +24% ARPU, Adapty) |
| 0.6 | **Doppelte ContentView-Instanz** beim Onboarding-Ende (fullScreenCover + onComplete parallel) | `OnboardingView.swift:100` | Flash/State-Bug am kritischsten Übergang |
| 0.7 | **Funnel-Events**: pro Onboarding-Screen ein Singular-Event + Paywall-Trigger-Source als Property (post-onboarding / cold-start / limit) + Paywall-Dismiss + Plan-Toggle | `OnboardingView.swift`, `PaywallView.swift` | Wir sind blind zwischen Install und `tutorial_complete` (11 Screens!). Install→Paywall-View ist DIE Metrik, die niemand published — Cal AI: 87% |
| 0.8 | **ATT-Copy fixen**: `NSUserTrackingUsageDescription` ist der maximal abschreckende Default ("deliver personalized ads to you") | `Info.plist` | DE hat 20% ATT-Opt-in — Copy nach AppsFlyer-Pattern (Schutz-Framing), Placement (spät, geprimed) ist schon richtig |
| 0.9 | **Config-Secrets**: Singular-Secret + Meta-Client-Token im Klartext eingecheckt | `Config.swift:10,14` | Hygiene |

---

## Phase 1 — Pricing (Woche 1–2) — **HUMAN-OWNED, ich propose, Deyar flippt**

Erwartung: **+40–70% RPD.** Reine Config-Änderung, reversibel, nur neue Cohorts (Bestand grandfathern).

**Neue SKU-Leiter (US / DE):**

| SKU | US | DE | Rolle |
|---|---|---|---|
| **Annual (DEFAULT, pre-selected)** | **$49.99** | **59,99 €** | Framing: "$0.96/week, billed annually". 14-Tage-Trial (Test, s.u.) |
| **Forever (one-time)** | **$79.99** | **99,99 €** | 1,6x Annual — NICHT 5x: es gibt kein Jahr 2, kein Kannibalisierungs-Risiko. Verkauft das Archiv ("Bis zum Ja-Wort & darüber hinaus") |
| Monthly (Decoy) | $12.99 | 14,99 € | Lifestyle-Median. Macht Annual offensichtlich richtig. Nie Default |
| Weekly | $6.99 | 7,99 € | NUR auf Secondary/Dismissal-Paywall |
| Annual-Discount | $29.99 | 39,99 € | Unser heutiger Preis wird das **Dismissal-Angebot**, nicht der Listenpreis |

- RC-Offerings sauber strukturieren (aktuell keine Offering-ID, kein A/B möglich) → `default` neu + Placements für Dismissal/Winback. Danach RC-natives A/B ohne Deploy.
- **Country-Price-Factors** über EU/UK/CH/CA rollen (Localization-Tests = höchste Win-Rate überhaupt, 62,3%; DE hat den höchsten Median-Monthly-Preis weltweit, $17.19). → `/asc-pricing` Skill.
- Verify live in ASC + RC nach dem Flip.

**Trial-Testmatrix (der wertvollste Test der ganzen Mission, 59,6% Win-Rate der Testklasse):**
1. 14-Tage-Trial (17–32d-Trials: 42,5% Trial→Paid vs. 25,5% bei ≤4d) — Favorit, überlebt auch "zeig ich am Wochenende meinem Verlobten"
2. Kein Trial, Direktkauf (Adapty: Lifestyle ist die EINZIGE Kategorie, wo Trials LTV senken, −21,2% — aber Wedding hat externe Deadline, verhält sich eher wie H&F, wo Trials +63,6% bringen → testen, nicht annehmen)
3. Paid Trial $1.99/7d

---

## Phase 2 — Onboarding-Rebuild (Woche 2–4)

Ist: 11 Screens, davon 2 generische Feature-Screens, 5 Dateneingaben ohne sichtbaren Payoff, 1 Review-Ask, 0 Social Proof, 0 personalisierter Output. Top-Grossing-Cluster: **28–45 Screens** (Cal AI 32 @ $35–50M ARR, Flo 43 @ $275M/yr). 78–90% aller Trial-Starts passieren an **Tag 0** — Onboarding IST der Funnel.

**Ziel: ~24 Screens → 3-seitige Paywall** (Multi-Page: +37% vs Single-Page, Superwall 40M Opens). Blueprint:

1. **Authority zuerst** (Rating + "X Paare planen mit uns") — killt die "The Knot ist gratis"-Objection bevor sie entsteht. NICHT mit einer Frage öffnen.
2. **8s-Demo**: Timeline populiert sich automatisch aus einem Datum (Produkt zeigen, nicht erklären — Cal AI)
3. **Hochzeitsdatum** → sofortiger Payoff: **Countdown-Reveal "247 Tage"** (der stärkste Input der App, treibt alles)
4. Planning-Stage → Branch (welches Modul gedemot wird)
5. Personalisierungs-Wellen mit sichtbarem Payoff pro Antwort: Gästezahl, Budget-Band, größter Stressor, Partner-Involvement, Traditionen (Differenzierung vs. US-Incumbents!)
6. Goal-matched Testimonials **mid-flow** (Flo-Pattern), Authority-Screens zwischen Frageblöcken
7. Outcome-Screen: "Paare mit deinem Budget sparen im Schnitt €3.200 mit getracktem Budget" (Outcome-Framing: +17% Trial, +13% ARPU)
8. **Notification-Preference-Screen** ("Wann erinnern? 6 Mon / 3 Mon / 2 Wochen vorher + Überfälliges" — Preference-Framing statt Permission, Daylio-Pattern) → dann erst System-Prompt
9. Partner-Invite (skippable) — Organic Loop am Peak-Engagement
10. **Plan-Reveal**: Name, Datum, Countdown, Task-Zahl, Budget-Split (die 12 Kategorien mit Prioritäts-Boost EXISTIEREN schon in `DataManager.swift:82` — werden dem User nur nie gezeigt!)
11. **Hold-to-Commit** ("Halte gedrückt, um dich zu deinem Hochzeitsplan zu committen" — Flo/Liftoff/Oniri, billigster High-Leverage-Screen)
12. Trust-Screen ("Wir erinnern dich 3 Tage vor Trial-Ende") → **3-seitige Paywall**: P1 Outcome + der gebaute Plan (locked), P2 Included + Review + FAQ, P3 Pricing (Annual default, "Try for $0.00"-CTA, "€49.99 vs. €20.000 Hochzeitsbudget"-Zeile, 3.1.2-compliant: echter Billing-Betrag groß lesbar, Trial-Timeline explizit, Restore + Terms)

**Budget-Frage in Landeswährung** (aktuell hart in $ — deutscher Nutzer plant in Dollar).

**Decline-Ladder (nicht optional — 90% der Erstviewer konvertieren nicht):**
Dismiss → 2 Diagnose-Fragen ("Was hält dich ab?") → zweite Paywall (3 Tiers, Reviews, Free-vs-Premium-Tabelle, $29.99-Offer) → limitierter Free-Tier → Welcome-Offer nach 24–48h (+10–15% ARPU). NIEMALS Rabatt auf der Haupt-Paywall (9 von 10 Subs verkaufen zum vollen Preis).

---

## Phase 3 — Gate härter ziehen (Woche 3–5)

Erwartung: **+50–100% RPD.** Ist-Zustand: faktisch alles gratis (Budget-Tab komplett frei, PDF-Export ungegated, `canExportData()`/`canAccessAllBudgetCategories()` werden NIRGENDS aufgerufen). Strategie: **"hard-ish"** — Soft-Floor der ASO schützt, aggressives Gate auf allem, was Lock-in erzeugt.

**Free forever** (schützt Ratings + Viralität): Countdown + Datum, Checkliste view-only (~5 abhakbar), 10 Gäste, 1 Budget-Kategorie.
**Gated**: volle Checkliste, unbegrenzte Gäste + RSVP, voller Budget-Tracker + Export, Vendor-Management, Partner-Sharing, (später) Sitzplan.

Konkret:
- `canAccessAllBudgetCategories()` + `canExportData()` endlich verdrahten; PDF-Export ([ProductionWeddingDaySchedule.swift:317](weddingplanner/Views/ProductionWeddingDaySchedule.swift#L317)) gaten
- **Task-Selbst-Sabotage fixen**: Onboarding legt exakt 5 Tasks an = `FREE_TASK_LIMIT` — User startet am Limit ohne je gehandelt zu haben. Free-Limit zählt nur user-erstellte Tasks ODER Checkliste wird view-only-Modell
- Paywall-Placement: Ende Onboarding nach Plan-Reveal (RC: +50% Paywall-Visibility, 2x Install→Trial; Rootd: 5x Revenue durch früheres Placement). Cold-Start-Paywall-Spam bei jedem Launch ([ContentView.swift:101](weddingplanner/ContentView.swift#L101)) durch gezielte Trigger ersetzen
- **Wächter-Metrik: Rating-Velocity + Keyword-Rank wöchentlich monitoren** — das einzige, was ernsthaft schiefgehen kann (Organic ist unser Traffic-Motor)

---

## Phase 4 — Recovery-Surfaces (Woche 5–8)

Erwartung: **+15–25% RPD.**
1. **Dismissal-Paywall**: Abandoner-Offers konvertieren 25%+ (Superwall). $29.99-Annual als "Once you close this, it's gone"
2. **Post-Purchase Forever-Upsell**: direkt nach Annual-Kauf "+$30 → Forever" — ~10% Take-Rate, ein Screen Arbeit, pure incremental
3. **Apple Win-Back-Offer bei T-60 Tage vor Hochzeitsdatum** — Panik-Season, der höchst-intente Winback-Moment der Kategorie. Wir KENNEN das Datum. (Churned-Monthly-Reaktivierung liegt inzwischen bei ~20%)
4. **Blinkist-Trial-Timeline-Screen** (+23% Trial-Signups): Today → Day 12 Reminder → Day 14 Billing, null Features, killt nur die "ich vergess zu kündigen"-Angst

---

## Phase 5 — App-Qualität (parallel, Woche 4–8)

Priorisiert nach ARPU-Wirkung, nicht nach Schönheit:

1. **Partner-Sharing / CloudKit-Sync** — größtes fehlendes Feature UND Organic-Loop (jede Hochzeit hat 2 Planende). Aktuell: CloudKit explizit deaktiviert, Single-Device, kein Backup. Gleichzeitig Premium-Anker-Feature
2. **Checklisten-Templates**: 12-Monats-Standard-Checkliste (aktuell nur 5 generierte Tasks aus ~6er-Pool) — Kern-Erwartung der Kategorie
3. **Währungs-Lokalisierung**: 8 hardcodierte USD-Formatter ([ProductionFundsView.swift:434](weddingplanner/Views/ProductionFundsView.swift#L434) etc.) + Budget-Ranges in $ → `Locale.current.currency`
4. **240 unübersetzte Strings** fertig übersetzen (de/es/fr/it) + strukturell unlokalisierbare `FeatureRow(text: String)` in der Paywall fixen → `/localize-app` Skill
5. **Sitzplan** — Seating Chart Planner verkauft NUR dieses Feature für $69.99–129.99/Jahr. Premium-Feature #1 fürs Winterupdate
6. **Datenverlust-Risiko**: In-Memory-Fallback bei Schema-Migration ([weddingplannerApp.swift:59](weddingplanner/weddingplannerApp.swift#L59)) killen, `VersionedSchema`/`SchemaMigrationPlan` einführen — vor JEDER Modell-Änderung Pflicht
7. **~5.100 LOC toter UI-Code löschen** (Elegant/Luxury/Modern/Flowing-Varianten, alle kompiliert via FileSystemSynchronizedGroup) + README auf Ist-Produkt updaten

---

## Phase 6 — Der differenzierte Bet (Woche 10+): Date-Aware Pricing

Kein einziger Wettbewerber macht das: **Preis ans Hochzeitsdatum koppeln** (Exam-Prep-Modell, UWorld/WedSites):
- ≤3 Monate: "Final Countdown Pass" $34.99 one-time (4 Mon Zugang)
- 4–9 Monate: $49.99 (12 Mon)
- 10–18 Monate: "Full Journey" $79.99 one-time (bis Datum + 6 Mon Archiv)

Macht die größte Schwäche (kurzer Lifecycle) zur legiblen Value-Prop, umgeht Trial-Kündigungsangst komplett. Höchste Varianz, höchstes Upside — erst nach Phase 1–4 validiert.

---

## KPI-Board & Testdisziplin

| Metrik | Ist | Ziel |
|---|---|---|
| RPD (D60) | $0.62 | **$1.50–2.00** |
| Install → Paywall-View | **unbekannt (blind!)** | >80% (Cal AI: 87%) |
| Install → Trial-Start (D30) | unbekannt | Median 5,8% → **12%+** (Top-Decile 20%) |
| Trial → Paid | unbekannt | **37%+** (H&F-Median, mit 14d-Trial 42%+) |
| Push-Opt-in | unbekannt | **50%+** (Median 49,4%, P90 74%) |
| Onboarding-Flow-Completion (in-session) | unbekannt | 90–95% |

- Min. 200 Subscriptions pro Variante; Pricing-Tests brauchen 3-Monats-Fenster (Refunds/Renewals)
- Entscheiden auf **Revenue per User, nie Conversion allein**
- Testreihenfolge nach Win-Rate: Trial-Struktur (59,6%) > Plan-Duration (58,7%) > Lokalisierung (62,3%) > Preis (45,5%) > Visual/Copy (34,6%) — **nie mit Visual anfangen**
- ATT: erst mit Paid UA scharf schalten (DE 20% Opt-in, ohne Kampagnen wertlos)

## Reihenfolge in einem Satz

**Woche 1: Bugs + Events. Woche 1–2: Preise (Deyar flippt). Woche 2–5: Onboarding + Gate. Woche 5–8: Recovery-Surfaces + Qualität. Alles live vor Dezember.**
