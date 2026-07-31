# Onboarding Teardown — is 26 screens right?

**Stand:** 2026-07-31 · Decision input for Wedding Planner: BridePlan · Author: research pass, secondary sources only (no competitor app was installed and run)

---

## Verdict

**Restructure — do not lengthen.** 26 is defensible but it is not a magic number, and there is no published evidence that screen 27 through 40 buys anything in our category. The long-onboarding playbook is real, but it is a **health-&-fitness / education pattern** (70% of all 26+ screen apps in a 953-app top-grossing sample sit in those two categories; only 3 of 77 Lifestyle apps do it, and all three are dating apps). It works there because it manufactures *belief that change is possible* — a belief our user already arrives with, because she is definitely getting married, on a date she already knows.

The binding constraint is not length, it is **payoff density**: 15 of our 26 screens are a question or a reassurance about a question, and a single 3.55-second loader carries the entire "we built something for you" claim. Fix the payoff, cut the 3–4 screens that collect data we throw away, and hold total length flat. If we later want to grow the flow, grow it *after* per-screen drop-off data exists, not before.

---

## 1. Competitor table — the wedding category

**Read this first:** four of the five biggest wedding apps do not sell subscriptions to couples at all. They monetize the *vendor* and the *registry*. Their onboarding incentive is the exact opposite of ours — every extra screen delays a couple from entering a marketplace where the money is. They are a **weak benchmark for us** and should not be used to argue "the category does short onboarding, so we should too." They do short onboarding because they are not selling to the person doing the onboarding.

| App | Onboarding length | Data collected | Paywall in onboarding? | Monetization | Confidence |
|---|---|---|---|---|---|
| **The Knot** (218k US ratings) | Could not determine a screen count. Account signup + wedding date + a "style quiz" is described in the listing; the quiz exists to match vendors, not to sell. | Wedding date, location, style/vibe quiz, budget, guest count | **No** — App Store listing shows **no in-app purchases at all**; marketed as "totally free" | Vendor marketplace leads + registry commission + stationery/invitation sales (The Knot Worldwide) | Monetization: **high** (verified on App Store listing). Length: **low** |
| **Zola** (95k US ratings) | Could not determine. Listing pitches speed explicitly: "Instant Registry… under 60 seconds", "your website can be [built in 5 minutes]" — i.e. deliberately fast | Names, date, registry prefs, website setup | **No subscription paywall.** À-la-carte IAPs exist *inside the product*, not in onboarding: Seating Chart $14.99, website animations $1.99–$9.99, Premium SMS $59.99/$79.99, disposable camera $40 | Registry commission + marketplace + paid one-off features | Monetization + IAP prices: **high** (App Store listing). Length: **low** |
| **WeddingWire / Wedding Planner by WeddingWire** (46k US ratings) | Could not determine | Date, location, vendor categories | **No** | Vendor leads (same parent as The Knot) | Monetization: **medium**. Length: **low** |
| **Joy (withjoy)** (8.7k US ratings) | Could not determine. Positioned as "the best free wedding website and app available" | Names, date, website/registry setup | **No** | Registry affiliate commission + optional upgrades (custom domain, SMS, printed stationery). ~$64.9M revenue reported 2023 | Monetization: **high**. Length: **low** |
| **Bridebook** (UK #1; only 223 US ratings) | Could not determine a screen count. Described as: create account → **enter wedding date** → checklist auto-generates month-by-month; budget breakdown built from "thousands of couples' actual spending" | Wedding date, budget, guest list, region | **No** — free to couples | Supplier marketplace; **vendors** pay for listing/enquiries/placement | Monetization: **high**. Length: **low** |
| **Appy Couple** (6.2k US ratings) | Could not determine | Wedding site/app setup, guest list, design theme | Paid up front, but it is a **purchase**, not a trial-based subscription funnel | **One-time fee: $49 (Boutique) / $149 (Luxury)**, custom domain ~$19.99/yr extra | Pricing: **high** (own pricing page). Length: **low** |
| **Minted (Weddings)** | Not audited in this pass | — | No | Print/stationery e-commerce | **low** |
| **Sevenlogics "Wedding Planner"** (3.7k US ratings) — the largest *indie* | Could not determine | — | Freemium; Premium subscription (ad-free + unlimited storage). Price not published | **Subscription** + ads | Model: **medium**. Price/length: **low** |
| **Wedsly / MyWed / Bridal Pro / BrideKit / Weddi** (all <400 US ratings) | Could not determine | — | Freemium with a premium tier | Subscription | **low** |
| **Wedding Planner: BridePlan (us)** | **26 screens**, then paywall | Names, date, stage, guest band, budget band, venue (free text), stressors, priorities, planning party | **Yes — hard-ish, at the end of onboarding** | Yearly + 14-day trial, one-time "Forever", monthly | **high** (own codebase) |

### What the table actually tells us

1. **There is no subscription incumbent to benchmark against.** The four apps with real scale are all free-to-couple. Every app that *does* sell a subscription to couples is sub-400 US ratings. So "what does the category do at onboarding" has almost no informational value for a subscription funnel — it tells you what a lead-gen funnel does.
2. **Nobody has torn down a wedding app.** I checked the two main teardown libraries: PaywallPro's 960-app open dataset has **zero** wedding-planning apps (it is revenue-ranked; we are all too small), ScreensDesign (2450+ apps) surfaced none, and onbo-hub's featured index has none. Confidence: **high** that no public onboarding teardown of a wedding app exists. That means (a) we cannot copy, (b) nobody is copying us either.
3. **Appy Couple's $49/$149 one-time is the single most useful competitive price datapoint here** — it validates a one-time SKU in this category at roughly our proposed "Forever" tier, from a company that has sold it for over a decade.
4. **Side finding, out of scope but free money:** BridePlan is listed on the App Store under **Utilities**, with no secondary genre. The Knot, Zola, WeddingWire, Joy and Bridebook are all **Lifestyle** (Zola and Joy carry a second genre too). Verified via the iTunes lookup API. That is an ASO/discovery problem, not an onboarding one, but it costs more than any onboarding screen.

---

## 2. Why long onboardings work elsewhere — and whether it transfers

### The base rate (this is the number that matters)

I pulled the **PaywallPro open paywall-gallery dataset** (960 top-grossing iOS subscription apps, observed screenshot captures of live flows, published on GitHub) and computed the distribution of onboarding screen counts myself. n=953 parseable rows:

| Onboarding screens | Apps | Share |
|---|---:|---:|
| 0 (none captured) | 179 | 18.8% |
| 1–5 | 217 | 22.8% |
| 6–10 | 320 | 33.6% |
| 11–15 | 104 | 10.9% |
| 16–20 | 52 | 5.5% |
| 21–25 | 28 | 2.9% |
| 26–30 | 20 | 2.1% |
| **31+** | **33** | **3.5%** |

- Median (all): **6**. Median excluding zeros: **7**. p90 = 21, p95 = 29.
- **Apps at 26+ screens: 53 of 953 = 5.6%.**
- Where those 53 live: **Health & Fitness 19, Education 18** (= 70% of them), Social Networking 6, **Lifestyle 3**, Music 2, Finance 2, Productivity 1, Photo & Video 1, Shopping 1.
- The three Lifestyle apps at 26+: Dil Mil (31, dating), WingAI (31, AI wingman), Kismia (26, dating). Lifestyle median is **6** (8 excluding zeros); max in the whole Lifestyle set is 31.
- Longest observed anywhere: Eato 68, Foodvisor 63, Flo 62, Natural Cycles 60, Boo 59, JustFit 53, Speech Blubs 52, Lifesum 51.

**Source quality: medium-high for the counts** (observed captures of live apps by a commercial crawler, published as an open dataset — this is measurement, not a marketing claim), **but note two biases**: it only contains top-grossing apps (survivorship), and their "onboarding vs walkthrough" split may misclassify some screens.

⚠️ Note on a number in `MISSION-3X-ARPU.md`: it cites "Flo 43 screens". This dataset observes **62** for Flo. Neither is necessarily wrong (flows are A/B tested and branch by answer), but treat any single quoted competitor screen count as ±50%.

### Does length predict revenue in that dataset? Essentially no.

| Onboarding bucket | n | Median est. MRR |
|---|---:|---:|
| 0 | 179 | $47K |
| 1–5 | 217 | $39K |
| 6–10 | 320 | $39K |
| 11–15 | 104 | $37K |
| 16–25 | 80 | $48K |
| 26+ | 53 | $61K |

Looks like a signal. It isn't a robust one. **Spearman rank correlation between onboarding length and estimated MRR across all 953 apps: −0.087.** Within category: Health & Fitness +0.023, Education −0.068, Lifestyle +0.037. All ≈ zero.

Honest reading: **long onboarding is a category norm, not a revenue predictor.** The 26+ bucket has higher median MRR mostly because it is 70% H&F/Education — high-ARPU verticals — not because the screens caused the revenue. And MRR is a *level*, heavily driven by paid-acquisition budget; it cannot establish causality about a conversion mechanic. Anyone (including a previous dossier) who points at "the top-grossing cluster does 28–45 screens" is looking at a category composition effect.

### The mechanisms, and how well each is actually sourced

| Mechanism | What it claims | Source quality |
|---|---|---|
| **Perceived personalization** | Questions signal "this product will be shaped around me" — the *promise* of customization does the work | **Medium-strong.** RevenueCat's own onboarding piece names it as the primary driver, and reports that **Lose It! found asking more questions increased trial starts by "double digits" — regardless of whether the answers were used.** That is the single strongest pro-length datapoint I found. It is a named app but an unquantified, non-replicated practitioner claim. |
| **Labor illusion / operational transparency** | Showing visible work makes people value the output more; people can prefer *longer* waits with visible effort over instant identical results | **Strong — this one has a real primary source.** Buell & Norton, "The Labor Illusion: How Operational Transparency Increases Perceived Value", *Management Science* 57(9), 2011, 1564–1579. Five experiments (travel and dating domains). This directly validates our `building_plan` screen. |
| **Commitment & consistency** (the hold-to-commit screen) | A micro-commitment before pricing raises follow-through | **Weak as published data.** Cialdini's principle is well-established academically; the *app* implementation (Flo's hold-to-commit, widely cloned) has **no published isolated lift number** I could find. Practitioner folklore, plausible, cheap. |
| **Authority / "science"** | BMI, TDEE, metabolic rate, cycle prediction — computations the user cannot do herself | **Observational.** RevenueCat: "What you notice about health & fitness apps is their use of 'science' in their marketing and onboarding." |
| **Sunk cost** | Having invested 3 minutes, the user is less willing to walk at the paywall | **Unsourced for apps.** Frequently asserted, no app-level evidence found. Also cuts the other way (see below). |

### The transfer question — argued both ways

**The case FOR going longer in wedding planning:**

- The Lose It! finding says the mechanism is *perceived* personalization, not real personalization. If that holds, it is category-agnostic and we should keep asking.
- A wedding plan is a genuine personalized artifact — arguably a better fit for the pattern than a calorie target, because the output (a 27-task checklist backwards-dated from *her* date, a budget split across *her* priorities) is visibly derived from the answers.
- Our monetization is a one-shot LTV: wedding engagement is ~15 months, there is no year two, so the first payment *is* the LTV. There is no "we'll convert her later" — onboarding **is** the funnel. Front-loading persuasion is correct.
- No competitor in the category runs a persuasive onboarding, so there is no norm to violate and no user expectation to break.
- RevenueCat 2026: hard paywalls convert **10.7%** day-35 trial-to-paid median vs **2.1%** freemium (~5x), ~8x revenue-per-install at day 60. If we are going hard-gate anyway, the onboarding has to carry the whole persuasion job, and short flows can't.

**The case AGAINST (and why it wins):**

- **The core disanalogy.** A weight-loss onboarding's real job is to manufacture *belief that change is possible* in someone who has failed before and doubts it. That is why it needs 40 screens of science and commitment. Our user does not doubt she is getting married. She has a ring, a date and a hard deadline. **The conviction the long flow exists to create is already at 100% before install.** What is uncertain for her is not "will this happen" but "is *this app* the one that handles it" — a much narrower question that does not need 40 screens, it needs one credible artifact.
- **Tonal contradiction.** Our own stressor screen offers "Having no time" as an option, and the payoff literally says *"The plan is already built. You only ever see the handful of things that matter this week."* Making a self-declared time-poor, stressed user answer twelve questions to hear that is a promise the flow's own length contradicts.
- **The authority ceiling is lower.** H&F can compute something the user cannot (TDEE, cycle prediction). Our "plan" is a template checklist with dates subtracted from her wedding day. Every extra question raises the expected sophistication of the reveal; if the reveal is a task list, more build-up increases the gap between promise and payoff, not the value.
- **RevenueCat's own onboarding guidance explicitly does not generalize the pattern.** Their piece names Me+ (45–50 screens, 7–10 minutes) and then says health & fitness "is somewhat unique in just how far this can be pushed." That is the source that the whole go-longer argument rests on, and it disclaims category transfer in the same article.
- **The base rate.** 3 of 77 Lifestyle apps run 26+, all dating. We are already at the outer edge of what the category does.
- **The two-minute problem.** RevenueCat reports **82% of trial starts happen on day 0** and **~80% of subscriptions happen within two minutes of download**, and their onboarding article warns against "burying the paywall" behind too many steps. Our 26 screens — 9 question screens, 10 tap-through payoff/preview screens, a 3.55s forced loader, plus welcome/social-proof/commit/notifications/timeline/recap — land the paywall somewhere around 2.5–4 minutes. *(That range is my estimate from the screen inventory and the one hard-coded duration in the code, not a measurement — see §5.)* The two-minute figure is partly circular (most apps show paywalls fast, so purchases happen fast) and dates to a 2018 analysis, so I would not treat it as a hard ceiling. But it does mean we are past the window most of the industry optimizes for, and it argues for **seconds-per-screen discipline over screen count**.

**Conclusion:** the mechanism is real, but its strongest published statement is category-scoped and self-disclaimed, and the base rate in our category is against us. Going to 35–40 screens would be a bet on folklore with no supporting evidence and a real tonal cost. Hold at ~26 (net), and spend the effort on payoff density.

---

## 3. Evidence on length vs conversion — and what is genuinely missing

| Claim | Number | Source | Quality |
|---|---|---|---|
| Hard paywall vs freemium, day-35 trial→paid | **10.7% vs 2.1%** (~5x); ~8x RPI at day 60 | RevenueCat *State of Subscription Apps 2026*, 115,000+ apps / $16B revenue | **Best available.** Large independent-ish dataset. **But it is about the gate, not about length.** |
| Trial length vs conversion | 17–32 day trials **42.5%** vs <4 day **25.5%** (~70% better) | RevenueCat SOSA 2026 | **High.** Adjacent to us: our trial is 14 days, sitting below the best-converting band. Worth a separate test — this is pricing/paywall, not onboarding. |
| Day-0 concentration | **55.4%** of 3-day-trial cancellations on day 0; 84% by day 1; 82% of trial starts on day 0 | RevenueCat SOSA 2026 / blog | **High** |
| Price tier vs download→trial | High-priced median **2.8%** vs low-priced **1.4%** | RevenueCat SOSA 2026 | **High**, and consistent with the pricing plan already in `MISSION-3X-ARPU.md` |
| Asking more questions lifts trial starts | "double digits", **even when the answers were unused** (Lose It!) | RevenueCat onboarding blog | **Medium-low.** Named app, no figure, no sample, not replicated. Strongest pro-length datapoint that exists. |
| Very long is viable | Me+ (UK #1 H&F): **45–50 screens, 7–10 minutes** | RevenueCat onboarding blog | **Medium** (observed), and explicitly framed as H&F-specific |
| Long onboarding vs **none**: +40% payment conversion iOS, +20% ARPU; then **shortening it cost −13%** | as stated | Adapty blog, "7 Mobile App Onboarding Best Practices in 2026", unnamed entertainment app | **VENDOR MARKETING + anecdote.** Adapty sells an onboarding builder and A/B tooling. Unnamed app, no sample size, no significance. This is the most-cited "go longer" stat in the ecosystem and it is one unnamed app in a vendor's blog. |
| Distribution of onboarding lengths across top-grossing apps | median 6; 5.6% at 26+; 70% of those in H&F/Education | PaywallPro open dataset, my own computation, n=953 | **Medium-high for counts** (observed), survivorship-biased |
| Length ↔ revenue correlation | **Spearman −0.087** overall, ≈0 within category | my computation on the same dataset | **Medium.** Rules out a strong monotonic effect in top-grossing apps; cannot rule out a within-app causal effect. |
| Labor illusion | people can prefer longer waits with visible work to instant identical results | Buell & Norton, *Management Science* 57(9) 2011 | **High — peer-reviewed primary source.** Lab experiments, not app funnels. |

**What does not exist, and this is the headline:**

**RevenueCat — the largest subscription dataset in the industry, 115k+ apps — publishes no onboarding-length benchmark at all.** I checked the 2026 report pages directly: no data on number of onboarding screens, no per-step drop-off, no paywall-placement-within-onboarding metric. Neither does anyone else with a real dataset. Every "optimal onboarding length" number circulating in this ecosystem is either (a) a *count* of what some app does, with no conversion attached, or (b) a vendor's single unnamed case study.

Also worth naming: **sites like onbo-hub are a sampling artifact.** Its featured index is entirely 12–43-screen flows ($20K–$500K/mo apps) because curating long onboardings is the site's premise. Looking at it and concluding "everyone runs 30+" is selecting on the dependent variable. The 953-app distribution above is the unbiased-ish base rate. (Mild counter-signal even within onbo-hub: its highest-revenue entries are among its *shorter* ones — Coconote $500K/mo at 25, Pingo AI $500K/mo at 23, Halo AI $300K/mo at 16.)

**Traffic-source interaction (question 4 in the brief): could not determine.** I found no published data on whether long onboarding hurts high-intent organic/ASA installs more than cold paid traffic. It is a reasonable prior — someone who searched "wedding planner app" wants the tool, someone served an ad does not yet — but I am labelling it **inference, unsourced**. We can measure it ourselves: `onboarding_step` drop-off segmented by Singular attribution source.

---

## 4. Concrete recommendation for our flow

Net effect of everything below: **26 → 25 screens.** Roughly flat length, materially higher payoff density.

### Cut / fix, in priority order

**P1 — `planning_party` (screen 17). Cut it.**
The only question in the flow whose answer is **never used**. `OnboardingData.party` is set by `OnboardingPartyScreen` and read nowhere: it is not passed to `DataManager.createWeddingWithDetails`, not used by `OnboardingChecklist.tasks`, not persisted to `UserDefaults`. Verified by grep across the whole target. It also sits in the worst possible position — the last question before the loader, i.e. the moment where the user is closest to the payoff and least tolerant of another tap.
*Caveat, and it is a real one:* the Lose It! finding argues that unused questions still lift trial starts. That is exactly the claim this cut contradicts. Cheap resolution — see §5: make this an A/B, it is one screen behind a flag.

**P2 — `venue` (screen 13). Convert from free text to chips, or cut.**
It is the only **keyboard-entry** question after the names screen, the only question with **no payoff screen** after it, and its output is a free-text string that seeds one field. Free text mid-flow is the highest-friction interaction we have. Replace with a 4-option tap: *Booked it · Viewing venues · Have a shortlist · No idea yet* — which is (a) one tap instead of a keyboard, (b) actually forkable into the checklist (someone with a booked venue should not see "Research venues" as task #4), and (c) earns its own payoff line. Keep the free-text venue name as an optional field inside the app, not in the flow.

**P3 — Three preview screens (`preview_checklist`, `preview_budget`, `preview_guests`) → collapse to two.**
This is the flattest stretch in the flow: three consecutive tap-throughs that show product rather than the user's own plan. Guests is the weakest of the three (the guest question was a 5-way band; there is least personal content to show back). Fold guests into the checklist preview.

**P4 — Lengthen the `building_plan` loader from 3.55s to ~8–10s and make the work legible.**
This is the cheapest high-leverage change in the whole flow and the only one with a peer-reviewed source behind it. Buell & Norton's finding is that *visible* work raises perceived value, and can make a longer wait preferable to an instant one. Right now a 3.2s progress ramp (`OnboardingPlanScreens.swift`, `total = 3.2`, +0.35s handoff) is carrying the credibility of twelve questions. Make the status lines quote her own answers back — "Weighting €35,000 toward photography and food…", "Dating 27 tasks back from 14 June 2027…", "Sizing the guest list for 100…". Same screen count, several times the perceived labor. **Do this one first — it is a one-file change.**

**P5 — Progress bar.** The code comments that progress is deliberately never rendered as "3 of 26". Correct call — but verify the bar does not *visibly* crawl through the twelve-question block. A bar that moves 4% per tap is a "this is long" signal by another route. Consider a segmented bar that completes a *section* (3 sections: about you / your plan / getting started) rather than a single 26-step ramp.

**P6 — Disable forward swipe.** The flow is a `TabView` with `PageTabViewStyle`; unless gestures are explicitly disabled, users can swipe forward and skip screens. On a 26-screen flow, the impatient segment will speed-run past the payoffs to reach the app, arriving at the paywall with none of the persuasion. Worth confirming and locking.

### Add — screens that would genuinely earn their place

These are ranked by *how visibly the answer changes the artifact she is shown*. That is the only test worth applying: an added screen earns its slot if the plan reveal is demonstrably different because of it.

**A1 — Ceremony type. The single strongest addition.**
The checklist master template in `OnboardingChecklist.swift` is 27 tasks and hard-codes one wedding: "Confirm your officiant", "Taste and order the cake", "Collect your marriage paperwork". There is **no ceremony-type branching at all**. A German user gets no Standesamt task. A Muslim user gets no nikah/mahr step. A Hindu user gets no multi-day structure. A civil-only couple gets an officiant task that means nothing. One tap — *Civil · Religious · Both · Not decided* (+ denomination follow-up where relevant) — forks the checklist materially, and its payoff screen writes itself: "We've added the four paperwork steps German couples always forget." This is the rare case where the added screen makes the product genuinely better *and* makes the reveal more credible. **Highest priority of anything in this document.**

**A2 — Partner / co-planner invite (before the paywall, not after).**
Ask for the partner's contact and offer to send them the plan. This does three things at once: it is a real commitment act (stronger than hold-to-commit, because it involves another person), it is a retention asset (two people in the plan churn less than one), and it makes "the two of us" an actual product state rather than a discarded answer. Only add if we ship shared/invite functionality — otherwise it is a lie and worse than nothing.

**A3 — A single "what would make this wedding a success" free-response or 3-option pick, quoted back at the paywall.**
Not another taxonomy question. One emotionally-loaded answer we can print verbatim on the paywall's first page above the price. Costs one screen, gives the highest-value surface in the app a personalized line.

**A4 — Reframe the trial-timeline screen against the wedding budget.**
Already planned in `MISSION-3X-ARPU.md` ("€49.99 vs €20,000 wedding budget"). Note we now have her actual budget band from screen 11 — use *her* number, not a generic one. Zero new screens, pure copy.

**Explicitly NOT recommended:** wedding style/vibe quiz (nothing in the product consumes it), city/region (would only earn a slot if we ship regional budget benchmarking — Bridebook's "thousands of couples' actual spending" is exactly this, and it is a product feature first, an onboarding question second), photo upload (adds a permission prompt and a failure mode mid-flow for a cosmetic payoff).

---

## 5. What we genuinely don't know, and what would settle it

We are about to have the data nobody publishes. `onboarding_step` fires per screen with a stable slug (`OnboardingFlowModel.swift` — the slugs are frozen deliberately, do not renumber them). Once live:

| Open question | What settles it |
|---|---|
| **Where do people actually leave?** No published benchmark exists for per-screen drop-off, so our own curve is the only real evidence we will ever have. | Drop-off by slug. Expect the cliff at the first *unrewarded* ask. My prediction, on record so it can be checked: the worst three are `venue` (keyboard, no payoff), `planning_party` (last ask before the payoff), and one of the three `preview_*` screens. |
| **How long does the flow actually take?** My 2.5–4 minute figure is an estimate from screen inventory, not a measurement. | Timestamp deltas between consecutive `onboarding_step` events → median seconds per screen and total time-to-paywall. This is more actionable than screen count: **seconds-to-paywall is the real variable, screens are a proxy.** |
| **Does the flow's length hurt or help?** Nothing published answers this for our category. | The only clean test: hold everything else constant and run 26 vs a ~16-screen cut (drop all payoff screens, keep every question) vs a ~34-screen extension. Measure install→paywall_view, install→trial_start, and trial→paid. **Do this after the current build has a baseline, not simultaneously with the pricing flip** — two changes at once and we learn nothing. |
| **Does the unused-question effect (Lose It!) replicate?** This is the crux of the P1 cut. | Flag `planning_party` on/off, 50/50. One screen, one flag, settles a real disagreement in the evidence. |
| **Traffic-source interaction.** Unsourced inference that high-intent organic tolerates length worse than cold paid. | Segment the same drop-off curve by Singular attribution source (ASA / Meta / organic). If organic drops off harder in the question block, that is a real finding and worth a shorter organic variant. |
| **Is the paywall or the onboarding the constraint?** We are optimizing onboarding while the paywall, price tier and gate are all changing. | Instrument `paywall_view` with a trigger-source property (already planned, Phase 0.7 of `MISSION-3X-ARPU.md`). If install→paywall_view is already >80%, onboarding length is **not** the bottleneck and further work here is rounding-error against the pricing and gate changes. |

**One thing to be honest about up front:** given ~93 US ratings and the current install base, we likely do not have the volume to reach significance on a 3-arm length test quickly. The realistic sequence is: ship the payoff-density fixes (P4, A1, P2 — none of which need a test to justify), get the baseline drop-off curve, and only spend statistical power on the length question if the curve shows a cliff. If it does not, 26 is fine and the leverage is elsewhere — which, per `MISSION-3X-ARPU.md`, it almost certainly is: the price tier and the gate are worth multiples of anything in this document.

---

## Sources

- [PaywallPro open paywall gallery dataset (960 apps)](https://github.com/paywallpro/paywall-gallery) — onboarding screen counts computed from `apps/index.md`
- [RevenueCat — State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps) · [10-minute summary](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026/) · [Business report](https://www.revenuecat.com/state-of-subscription-apps-2026-business/)
- [RevenueCat — Why your onboarding experience might be too short](https://www.revenuecat.com/blog/growth/why-your-onboarding-experience-might-be-too-short/)
- [RevenueCat — Stop chasing growth hacks, fix your onboarding funnel first](https://www.revenuecat.com/blog/growth/fix-onboarding-funnels/)
- [Adapty — 7 Mobile App Onboarding Best Practices in 2026](https://adapty.io/blog/how-to-fix-your-onboarding-flow/) *(vendor)*
- Buell & Norton, [The Labor Illusion: How Operational Transparency Increases Perceived Value](https://pubsonline.informs.org/doi/10.1287/mnsc.1110.1376), *Management Science* 57(9), 2011
- [The Knot — App Store listing](https://apps.apple.com/us/app/the-knot-wedding-planner/id457941553) · [Zola — App Store listing](https://apps.apple.com/us/app/zola-wedding-planner/id852691916) · [Appy Couple pricing](https://www.appycouple.com/pricing/) · [Bridebook](https://bridebook.com/uk) · [Joy pricing](https://withjoy.com/pricing/)
- [onbo-hub](https://onbo-hub.com/) *(curated long-onboarding showcase — selection-biased by design)* · [ScreensDesign](https://screensdesign.com/)
- App Store category/genre data via the iTunes Search & Lookup API
