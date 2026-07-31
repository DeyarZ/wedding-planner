# Onboarding Teardown — is 26 screens right?

**Stand:** 2026-07-31 · Decision input for Wedding Planner: BridePlan
**Method:** desk research. No competitor iOS app was installed and run. Zola's and Joy's *web* onboarding were walked directly (high confidence); everything else in-app is from App Store listings, the iTunes Lookup API, Apple's customer-review RSS feed, published teardowns and screenshot galleries. Confidence is labeled per claim. Reddit blocks our crawler, so user complaints come from Apple's official review feed instead.

---

## Verdict

**Restructure now; treat length as the *second* test, not the first — and if we ever do test length, test it upward, not downward.** 26 is inside a defensible band, but it was picked from a benchmark that doesn't survive scrutiny (see §2), and nobody on earth — including RevenueCat's 115,000-app dataset — has published data linking onboarding length to subscription conversion. Anyone quoting an optimal number, including our own prior dossier, is quoting a *screen count* with no conversion attached.

What the evidence does support: the binding constraint is **payoff density and typed-field friction, not screen count**. 15 of our 26 screens are a question or a reassurance about a question; three of them require a keyboard; one 3.55-second loader carries the entire "we built something for you" claim; and one question's answer is collected and thrown away. Fix those — none of it needs an A/B test to justify — then get the per-screen drop-off curve, which nobody else in this category has, and let it decide the length question.

Honest caveat against my own conclusion: among apps whose *product is a generated personalized plan* (which we are), the observed norm in curated teardown libraries is **35–55 screens, indie median ~35** — above us, not below. And the only team that has publicly described iterating to the ceiling (Lose It!, 50M users) went to **79** and stopped only at diminishing returns. That is a real argument for longer and I am not dismissing it — I am saying we cannot afford to iterate blind at our volume, and the cheap wins are elsewhere first.

---

## 1. Competitor table — the wedding category

**Read this first.** Every wedding app with real scale is free to couples. They monetize the *vendor*, the *registry* or the *print order*. Their onboarding incentive is the inverse of ours: every screen delays a couple from reaching the marketplace where the money is. **They are a weak benchmark for a subscription funnel** and must not be used to argue "the category does short onboarding, so we should too." They do short onboarding because they are not selling to the person doing the onboarding. Their *sequencing*, however, is still worth stealing.

### Tier 1 — the marketplace giants (NOT valid subscription benchmarks)

| App | Onboarding length | Data collected | Paywall in onboarding? | Monetization | Confidence |
|---|---|---|---|---|---|
| **Zola** (95k US ratings, 4.91★) | **3 phases, verified end-to-end on web.** Stepper literally reads `1 Get started · 2 The basics · 3 Finish up`. ① *"Where are you in the planning process?"* — 5 options (not yet engaged / newly engaged / planning, no venue / planning, venue booked / almost done). ② names + partner names + wedding date ("all fields required", with a "we're still deciding" escape). ③ **account gate** — Google / Apple / email. Listing pitches speed: registry "under 60 seconds" | Planning stage, both names, date. **Not** collected: guest count, budget, location, style | **No.** À-la-carte IAPs sit deep *inside* the product, not in onboarding: Seating Chart $14.99, website animations $1.99–$9.99, Premium SMS $59.99/$79.99, disposable camera $40 | Registry retail margin + cash-fund fees + vendor commissions + stationery | Flow: **high** (walked). IAP: **high** (listing) |
| **The Knot** (218k US ratings, 4.86★) | **Account required before anything** — their own FAQ: *"Once you open the app, you'll be asked to log in or sign up."* Screen count: **could not determine** — no teardown or capture exists | Date, city, names, estimated guest count, budget range. Style Quiz appears **optional**, not a gate | **No.** No IAP on the listing or in the Lookup API. *"Completely free to use with no hidden fees"* | 100% vendor advertising — vendors pay for placement, 12-month contracts, ranking by spend | Gate + monetization: **high**. Length: **could not determine** |
| **Joy (withjoy)** (8.7k US ratings, 4.81★) | **Account is screen one, verified.** `withjoy.com/createwedding` hard-redirects to `/create-account`: "Hi! Let's get started" → email + password. Nothing precedes it. In-app screen count: **could not determine** | Post-signup: event details, website, guest list, invitations, RSVPs | **No.** No IAP | Registry commissions + paid print/stationery + a travel-booking concierge | Gate: **high** (walked). Length: **could not determine** |
| **WeddingWire** (46k US ratings) | **Could not determine** | Date, location, vendor categories | **No.** No IAP | Vendor marketplace (250k+ vendors). Same parent as The Knot | Monetization: **high** |
| **Hitched** (UK, 4.4k GB ratings) | **Could not determine** | — | **No.** No IAP | The Knot Worldwide again — UK vendor marketplace + awards sponsorships | Monetization: **high** |
| **Bridebook** (UK #1) | Account required; **could not determine** a count. Described flow: sign up → wedding date → checklist auto-generates month-by-month; budget split modeled on "thousands of couples' actual spending" | Date, budget, guest list, region | **No.** Bridebook's own support: *"every couple can use Bridebook completely free… right through to their wedding day."* No IAP on the listing | Supplier marketplace — **vendors** pay | **High.** ⚠️ Their live Subscription ToS still describes a consumer *"Bridebook VIP"* (7-day trial, monthly/annual IAP). No such SKU exists on the listing — treat as **dead/legacy**, not a live subscription benchmark |
| **Minted** | **N/A — there is no Minted wedding planner app.** The only Minted iOS app is "Minted: The Address Book". Wedding websites are free on the web; custom URL $15 one-time; building one grants a $50 stationery credit | — | — | Print/stationery commerce. The free website is a pure loss-leader | **High** (iTunes Search API) |
| **Appy Couple** (6.2k US ratings) | **Could not determine** | Site/app setup, guest list, theme | Hosts pay, guests free — but it is an **event-lifetime licence**, not a churning subscription | **IAP: $11.99 / $49.99 / $99.00** (App Store). Web pricing quoted as $99/yr or $12/mo, and elsewhere as $49 Boutique / $149 Luxury one-time — **the web and IAP price ladders do not match; treat the exact numbers as unsettled, the model as clear** | IAP prices: **high**. Web pricing: **medium** |

### Tier 2 — apps in the original brief that don't exist

| App | Status |
|---|---|
| **Wedding Happy** | **Delisted.** iTunes Lookup on `id432763910` returns `resultCount: 0` across 7 storefronts. Site still live, binary gone. Historic model was a one-time unlock. **High** |
| **WeddingHero** | **Never shipped.** weddinghero.app is a "Launching Soon" placeholder, not in the App Store index. **High** |
| **Wedbuddy** | **No iOS app.** Closest is "Weddy Buddy", Google Play only. **Medium-high** |
| **Aisle Planner** | B2B SaaS for professional planners, $39.99–$169.99/mo. Wrong category. **Medium** |

### Tier 3 — the actual subscription indies (our real benchmark set)

All prices read from live App Store listings — **high confidence**. Onboarding lengths: **could not determine for any of them** (none has a published teardown).

| App | Pricing | Note |
|---|---|---|
| **UNSTAGED** (WEST DESIGN LAB, SE) | **$19.90/mo · $79.99/yr · $149 forever**, 7-day trial | **Subscription required to use** — and *zero* paywall complaints in reviews. Highest price in the category. Running Instagram ads |
| **Daily I Do** | $3.99/wk · $6.99/mo · **$29.99 AND $39.99/yr** · $19.99 lifetime, 7-day trial | Two live yearly SKUs = an active price test **upward**. 4.8★/182 in ~5 months |
| **MyWed** | $5.99/mo · $19.99/6mo · **$29.99/yr · $59.99 forever** | Most mature indie, 1M+ Play downloads. Free tier caps at 20 guests (*medium*) |
| **Wedsly** | $4.99/mo · $49.99/yr | Account required, ad-free positioning |
| **Aisle** | $4.99/mo · $39.99/yr ($19.99 intro) | **Metered freemium** — free caps at 5 budget categories / 50 guests / 5 vendors |
| **Wedcheese** · **MatriMoney** · **Harmony** · **Weddi** | $4.99–$46.99 range | Smaller; Weddi also sells $1.99 consumable AI credits |
| **Explicitly not subscription** | Sevenlogics *Wedding Planner* (3.7k ratings) = **$0.99** + ads · BrideKit = $8.99 lifetime · *Wedding Countdown* markets **"No account required. No sign-up."** as a feature · *Wedding Budget* markets **"100% Free. No subscriptions. No paywalls. No catch."** | |
| **BridePlan (us)** | **26 screens → paywall.** Collects: names, date, stage, guest band, budget band, venue (free text), stressors, priorities, planning party | **high** (own codebase) |

### What the table actually tells us

1. **There is no subscription incumbent to benchmark against.** Every app with scale is free-to-couple; every app selling a subscription to couples is small. "What does the category do at onboarding" therefore has almost no informational value for our funnel — it describes a lead-gen funnel.
2. **Nobody has torn down a wedding app, ever.** PaywallPro's 960-app open dataset contains **zero** wedding planning apps (it is revenue-ranked; we are all too small). ScreensDesign (2450+ apps) and onbo-hub surfaced none. **High confidence.** So on a long quiz-style wedding onboarding there is **no competitor evidence either for or against** — we would be first. That is either the edge or the warning.
3. **Zola's sequencing is the transferable asset, and it is the opposite of Joy's.** Zola asks two personalizing questions *before* the account gate; Joy demands email+password on screen one. Zola is the one with 95k ratings at 4.91★. We already do this right (no account gate at all) — worth not breaking.
4. **Zola's first question is planning stage + venue status, exactly like ours.** Independent convergence on that being the right opening question. Ours is on screen 7; theirs is screen 1.
5. **Gating *access* reads as fraud; gating *depth* does not.** The 1★ reviews cluster hard on apps that blocked a core input or silently converted a trial — *Wedding Countdown*, 1★ **"NOT FREE"**: *"I couldn't even put my date in cause you HAVE to purchase it… I'm downloading something else."* Zola, 1★: *"Claiming the app is entirely free and then charging to make a seating chart is wild."* Daily I Do, 1★: *"They don't tell you that your trial is ending… just steals money from brides who are desperate for help."* Meanwhile **UNSTAGED requires a subscription at $79.99/yr and takes zero paywall complaints**, because the value is legible before the ask. **Directly relevant to our hard-gate plan: the gate is survivable; the surprise is not.** Confidence **high** — verbatim from Apple's review RSS.
6. **Almost nobody complains about onboarding length.** ~215 low-star reviews mined across the big four; the complaints are bugs, RSVP data loss, vendor spam and support — not signup friction. *But do not over-read this:* all four have short onboardings, so the absence of length complaints is expected and tells us little about a 26-screen flow.
7. **Pricing observation, not a recommendation** (pricing is human-owned): UNSTAGED sits at $79.99/yr and Daily I Do is actively testing $29.99 → $39.99/yr. The category has demonstrably borne more than our current annual. That lines up with the plan already in `MISSION-3X-ARPU.md`.
8. **Side finding, out of scope but free money:** BridePlan is listed on the App Store under **Utilities** with no secondary genre. The Knot, Zola, WeddingWire, Joy and Bridebook are all **Lifestyle**. Verified via the iTunes Lookup API. An ASO problem, not an onboarding one — and worth more than any screen in this document.

---

## 2. Why long onboardings work elsewhere — and whether it transfers

### 2a. Two populations, two very different base rates

This is where most people get confused, so keep the populations separate.

**Population A — all top-grossing subscription apps.** I pulled the **PaywallPro open paywall-gallery dataset** (960 apps, observed captures of live flows, published on GitHub) and computed the distribution myself, n=953:

| Onboarding screens | Apps | Share |
|---|---:|---:|
| 0 (none captured) | 179 | 18.8% |
| 1–5 | 217 | 22.8% |
| 6–10 | 320 | 33.6% |
| 11–15 | 104 | 10.9% |
| 16–20 | 52 | 5.5% |
| 21–25 | 28 | 2.9% |
| 26–30 | 20 | 2.1% |
| 31+ | 33 | 3.5% |

Median **6** (7 excluding zeros); p90 21, p95 29. **Only 5.6% run 26+.** Of those 53: **Health & Fitness 19, Education 18** (70% of them), Social 6, **Lifestyle 3**, Music 2, Finance 2, Productivity 1, Photo/Video 1, Shopping 1. The three Lifestyle apps at 26+ are Dil Mil (31), WingAI (31), Kismia (26) — all dating. **Lifestyle median: 6.** Longest observed anywhere: Eato 68, Foodvisor 63, Flo 62, Natural Cycles 60, Boo 59, JustFit 53, Speech Blubs 52, Lifesum 51.

**Does length predict revenue there? No.** Median est. MRR by bucket: 0 → $47K, 1–5 → $39K, 6–10 → $39K, 11–15 → $37K, 16–25 → $48K, 26+ → $61K. Looks like a signal; isn't one. **Spearman rank correlation between length and MRR across all 953: −0.087.** Within category: H&F +0.023, Education −0.068, Lifestyle +0.037. All ≈ zero. The 26+ bucket's higher median is a **category composition effect** — it is 70% H&F/Education, high-ARPU verticals — not a causal effect of screens. Anyone pointing at "the top-grossing cluster does 28–45 screens" (including our own prior dossier) is reading composition as causation.

**Population B — apps whose product is a generated personalized plan.** Verified counts from screenshot galleries with capture dates (reteno, tasu, onbo-hub, theappfuel):

| App | Screens |
|---|---|
| Noom (**web** funnel, 10–15 min) | 109–113 |
| Yazio | 80 / 60+ |
| **Lose It!** | **79** |
| Simple | 55 |
| Me+ | 45–50 |
| Fabulous | 37–45 |
| Liftoff | 42 |
| RISE | 41 |
| BetterMe | 38–39 |
| Hinge | 37 |
| Finch | 28–36 |
| Cal AI | 20 / 28 / 32 (sources disagree) |
| Freeletics | 26 |
| MyFitnessPal | 23 |
| Bumble | 22 |
| Fitbod | 18 |
| Co-Star | 18 |

onbo-hub's indie subscription index (Wayk 43, Purpose 41, CleanEats 41, Erly 41, Aya 38, Sprout 38, Calo 37, Befit 35, Sway AI 33, Jungle 30, MeAgain 27) runs a **median around 35**. **In population B, we at 26 are below the norm, not above it.**

**And the counterexamples inside population B matter:** Calm **7** and Headspace **12–17** are among the most successful subscription apps in existence. Sleep Cycle **6**. Airlearn deliberately runs **6** as an explicit anti-Duolingo bet. The split tracks *what the product is*: where the output is a **personalized plan**, flows are long; where the value is an **immediate experience**, they are short.

⚠️ Two data-hygiene notes. (a) `MISSION-3X-ARPU.md` cites "Flo 43 screens"; PaywallPro observes **62** and other sources say ~40 for the web funnel. Flows are A/B tested and branch by answer — treat any single competitor screen count as **±50%**. (b) Duolingo is quoted at both 38 and 17 depending on where the flow boundary is drawn. Screen counts are softer numbers than they look.

**Which population are we?** Genuinely both. Our *category* is Lifestyle (population A, median 6). Our *product* is a generated personalized plan (population B, median ~35). We sit at 26, between them. That is not an accident of laziness — it is a reasonable straddle — but it does mean **26 is not derived from anything; it is a midpoint.**

### 2b. The mechanisms — which have real primary sources

| Mechanism | Primary source | What it actually shows |
|---|---|---|
| **Labor illusion** | Buell & Norton 2011, *Management Science* 57(9):1564–1579 | Five experiments (online travel, online dating): people **preferred sites with longer waits** when the wait displayed visible effort, even with identical results. Mediated by perceived effort → reciprocity. **Tested on exactly our `building_plan` pattern.** Strongest citation we have. |
| **Foot-in-the-door / commitment** | Freedman & Fraser 1966, *JPSP* 4(2):155–202 | Small request first → **53% complied** with the large request vs **22%** control. The actual source behind Cialdini's chapter — and behind our `commit` screen. |
| **Effort justification** | Aronson & Mills 1959, *J. Abnormal & Social Psych* 59:177–181 | Severe initiation → more liking for the group. |
| **IKEA effect** | Norton, Mochon & Ariely 2012, *J. Consumer Psych* 22(3):453–460 | Labor raises valuation — **but only when the labor is successfully completed.** Incomplete or destroyed builds killed the effect entirely. **This is the boundary condition that governs the whole length decision — see below.** |
| **Endowed progress** | Nunes & Drèze 2006, *JCR* 32(4):504–512 | Car wash: 10 stamps with 2 pre-filled → **34% redemption vs 19%** for a bare 8-stamp card. Same real work, reframed as "already started." Directly actionable on our progress bar. |
| **Effort → willingness to pay** | Lala & Chakraborty 2015, *J. Consumer Marketing* 32(2):61–70 | Consumers made to work harder evaluating brands paid more. Closest thing to a source for "anchor the price after effort" — but a brand-evaluation lab study, not a paywall. |
| **Sunk cost over time** | Soman 2001; contested 2023 registered replication in *IRSP* | **The folklore is shakier than practitioners assume.** Sunk-cost is *weaker* for time than for money; replication was mixed. "Users won't abandon after 8 minutes invested" rests on a contested effect. |
| **Hold-to-commit as an app pattern** | — | **No published isolated lift number exists.** Widely cloned from Flo. Plausible, cheap, unproven. |

**The honest framing:** these are real psychology, demonstrated in labs on car washes, origami and travel-search waits. **Nobody has run the experiment on a 40-screen iOS onboarding funnel.** The transfer is plausible, not demonstrated.

### 2c. Does it transfer to wedding planning? Both sides.

**FOR going longer:**

- **The single best practitioner datapoint says longer, and says where it stops.** Paul Apollo, SVP Ops at Lose It! (50M users), on the Sub Club podcast: *"Our trial take rates went up double digits as onboarding got longer. We basically just kept making it longer and longer and longer **until we got diminishing returns**."* Lose It! ended at **79 screens**. RevenueCat's writeup adds that Lose It! reports the lift held **regardless of whether the answers were used** — i.e. the mechanism is *perceived* personalization, which would transfer to any category.
- **A wedding plan is a genuinely personalized artifact** — arguably a better fit for the pattern than a calorie target, because the output (27 tasks backwards-dated from *her* date, a budget split across *her* priorities) is visibly derived from the answers. That puts us squarely in population B, where the norm is ~35.
- **One-shot LTV.** Wedding engagement is ~15 months; there is no year two. The first payment *is* the LTV. There is no "we'll convert her later" — onboarding **is** the funnel, and front-loading persuasion is correct.
- **No competitor norm to violate.** Nobody in the category runs a persuasive onboarding, so there is no user expectation to break.
- **Baymard's checkout research cuts in our favor.** 200,000+ research hours, 335+ sites: *"the number of form fields in a checkout impacts overall usability far more than the number of steps."* 40 tap-one-of-four screens impose far less load than 12 typed fields. (Caveat: web checkout, a known-goal purchase context, not pre-value onboarding.)

**AGAINST (and why it wins, for now):**

- **The core disanalogy.** A weight-loss onboarding's real job is to manufacture *belief that change is possible* in someone who has failed before and doubts it. That is why it needs 40 screens of "science". **Our user does not doubt she is getting married.** She has a ring, a date and a hard deadline. The conviction the long flow exists to create is already at 100% before install. What is uncertain for her is not "will this happen" but "is *this app* the one that handles it" — a much narrower question that does not need 40 screens; it needs one credible artifact.
- **The IKEA-effect boundary condition is the actual risk, and we cannot currently see it.** Labor only produces attachment on **successful completion**. Every user who abandons at screen 20 got 100% of the cost and 0% of the benefit — strictly worse than never having asked. **We do not know our completion rate.** Lengthening a flow whose completion rate is unmeasured is the one move the research specifically warns against.
- **The authority ceiling is lower.** H&F computes something the user cannot (TDEE, cycle prediction). Our plan is a template checklist with dates subtracted from her wedding day. Every extra question raises the expected sophistication of the reveal; more build-up widens the gap between promise and payoff.
- **Tonal contradiction.** Our own stressor screen offers "Having no time", and its payoff literally says *"The plan is already built. You only ever see the handful of things that matter this week."* Making a self-declared time-poor, stressed user answer twelve questions to hear that is a promise the flow's own length contradicts.
- **Survivorship is the whole problem with population B.** Fabulous's 42 and Noom's 113 are observations that *successful* apps do it, not evidence it caused the success. Nobody publishes the flow lengths of apps that died — and RevenueCat's 2026 data notes **57.7% of new subscription apps never cross $1,000 in revenue**. None of them have teardowns.
- **We cannot afford Lose It!'s method.** Their answer came from iterating with A/B tests at 50M users. At ~93 ratings we cannot walk that curve; we have to pick a point. Picking further out, blind, with an unmeasured completion rate, is a bet — not a decision.

**Conclusion:** the mechanism is real and the pro-length case is stronger than I initially credited it. But its two load-bearing supports — Lose It!'s podcast quote and population B's median — are respectively one unquantified anecdote and a survivorship-selected sample, and the governing research (IKEA effect) says the downside of over-lengthening is concentrated exactly where we are blind. **Hold at ~26 net, fix payoff density, get the drop-off curve, then test upward.**

---

## 3. Evidence on length vs conversion — source quality labeled

### What is actually settled

| Claim | Number | Source | Quality |
|---|---|---|---|
| Paywall belongs inside session 1 | 82% of trial starts on day 0 (RC 2025); **89.4%** day-0 (Adapty, days 1–3 add only 2.0%); 55.4% of 3-day-trial cancellations on day 0 | RevenueCat SOSA 2025/2026; Adapty SOIS 2026 | **STRONG.** Three vendors, three datasets, converging |
| Hard paywall vs freemium | **10.7% vs 2.1%** D35 (~5×); RPI D60 $3.09 vs $0.38 (8×); 12-mo retention nearly identical (27% vs 28%) | RevenueCat SOSA 2026 — 115,000+ apps, $16B, 1B+ transactions | **STRONG.** About the *gate*, not length |
| Trial length | 17–32 days **42.5%** vs ≤4 days **25.5%** | RevenueCat SOSA 2026 | **STRONG.** Adjacent: our 14-day trial sits below the best band |
| Price tier | High-priced download→trial **2.8%** vs low-priced **1.4%** | RevenueCat SOSA 2026 | **STRONG** |
| Multi-page paywall beats single-page | **9.07% → 12.41%** (+37%) | Superwall — 40M+ paywall opens Feb–May 2026, onboarding placements only, min. 50 opens/paywall | **MODERATE.** Vendor, but the best-documented methodology in the set. Correlational; no control for category or team quality. Our 3-page paywall plan is on the right side of this |
| Paywall placement ranking | onboarding+trial 1.35% > in-app+trial 0.89% > onboarding no-trial 0.82% > in-app no-trial 0.76% | Adapty SOIS 2026, 16,000+ apps | **MODERATE.** ⚠️ Adapty publishes **1.78%** for the same segment in two other posts from the same report. **Use the ordering, not the absolute value.** |
| Intent beats everything | Apple Ads install-to-paid **1.92%** vs other paid **0.91%** (2.1×); trial initiation 3.66% vs 1.45% (2.5×) | Adapty, 1M+ Apple Ads ad groups, Jul 2026 | **MODERATE.** Vendor, but large n |

### What is NOT settled — onboarding length

| Claim | Source | Quality |
|---|---|---|
| Long onboarding vs **none**: +40% payment conversion iOS, +20% ARPU; **shortening it then cost −13%** | Adapty blog, unnamed entertainment app | **WEAK.** Vendor that sells onboarding builders. No app name, no N, no duration, no significance. And the headline comparison is long-vs-*nothing* — not our question. Only the −13% speaks to length at all |
| "Trial take rates went up double digits as onboarding got longer… until we got diminishing returns" | Paul Apollo, Lose It!, Sub Club podcast + RevenueCat writeup | **WEAK as data, strongest we have.** Named exec, named 50M-user app, A/B-tested internally — but no figures published |
| Lengthening onboarding → ARPU +14%, install-to-sub +15.4%, **11.7% churned before the paywall** | Instories, practitioner Medium post | **WEAK.** Self-reported, no N. The 11.7% pre-paywall churn number is the useful part |
| Length distribution ~35–55 for plan-generating apps | reteno / tasu / onbo-hub galleries | **MEDIUM for the counts, WEAK as guidance.** Observed captures, but curated *because* they are long — selecting on the dependent variable |
| **Removing** a loading screen → **+22% trial conversions, +30% ARPU** | Adapty, same blog page | **WEAK, and it points the other way.** Notable that Adapty publishes a result against its own thesis — mildly raises trust in the set. **Directly contradicts our loader recommendation; see §4/P4** |

**The headline:** **RevenueCat's 115,000-app dataset publishes no onboarding-length benchmark at all** — no screen counts, no per-step drop-off, no placement-within-onboarding metric. I checked the 2026 report pages directly. Neither does anyone else with a real dataset. There is **no peer-reviewed research** linking mobile onboarding length to subscription conversion. Adapty's own conclusion on its own page is *"It's not about length, it's about how you use it… there's no magic number"* — and it explicitly declines to endorse Fabulous's 42 screens as a benchmark.

**On traffic source (brief question 4): could not determine.** The direction — cold paid needs warming, high-intent organic doesn't — is the consensus practitioner view (FunnelFox states it explicitly, with **no supporting data**) and is mechanistically coherent with the 2.1× Apple Ads intent gap. **Nobody has published onboarding length segmented by traffic source.** Labeled **inference**. We can measure it ourselves.

### Numbers circulating widely that we must NOT cite

Flagged because they will otherwise turn up in our own decks:

- **"87% of people have left an onboarding flow because it wasn't clear"** — appears at Adapty with no source. **No primary study exists.** Chain fully broken.
- **"77% of users churn within 3 days"** — traces to Andrew Chen / Quettra **2015**, Android-only, and the original says **DAUs**, not users. At least two circulating attributions are wrong. 11 years old; Quettra no longer exists.
- **"25% of apps are used only once"** — Localytics, **2015** (already 23% by 2016). Primary posts are dead links.
- **"20–40% drop-off between screen 1 and screen 3"** — UXCam, attributed to "Baymard, AppsFlyer, NN/g and UXCam pattern data" with **no specific citation and no disclosed N**.
- **"3–5 screens converts 40–60% better", "a Health & Fitness user will sit through 25 screens"** — SEM Nexus, Jul 2026. Fetched and checked: **zero citations, zero links to any data.** Invented-looking precision.
- **"Users who experience value within 60 seconds are 3–5× more likely to stay"**, **"effective onboarding → 50% better retention"** — unsourced blog assertions.
- Any **AppsFlyer** onboarding-retention claim seen in third-party blogs — no primary AppsFlyer page carrying them could be reached.

---

## 4. Concrete recommendation for our flow

Net effect: **26 → 25 screens.** Roughly flat length, materially higher payoff density and lower typed-field friction. Nothing below requires an A/B test to justify except where noted.

### Cut / fix, in priority order

**P1 — Make the `building_plan` loader's work legible. Do this first; it is a one-file change.**
Currently `total = 3.2` seconds plus a 0.35s handoff (`OnboardingPlanScreens.swift`). A 3.55-second generic ramp is carrying the credibility of twelve questions. Buell & Norton is the one peer-reviewed source we have and it says the mechanism is **visible, specific effort** — so make the status lines quote her own answers: *"Weighting €35,000 toward photography and food…"*, *"Dating 27 tasks back from 14 June 2027…"*, *"Sizing the guest list for 100…"*.
⚠️ **Honest conflict:** Adapty reports an app that **removed** a loading screen and gained +22% trial conversions / +30% ARPU. So do the *legibility* change unconditionally (that is the Buell & Norton mechanism and it costs nothing), and treat the **duration** as contested — ship at ~6s and A/B 3.5s vs 6s vs 10s later rather than assuming longer is better.

**P2 — Kill typed fields. `venue` (screen 13) → tap options.**
Baymard's finding is that **fields matter far more than steps** — which means our three keyboard screens cost more than several tap screens. `venue` is the worst offender: the only keyboard entry after the names screen, the only question with **no payoff screen** after it, and its output is a free-text string seeding one field. Replace with a four-option tap — *Booked it · Viewing venues · Have a shortlist · No idea yet* — which is (a) one tap instead of a keyboard, (b) actually forkable into the checklist (a couple with a booked venue should not see "Research venues" as task #4), and (c) earns its own payoff line. Keep free-text venue name as an optional field inside the app. **This is the highest-value single change after P1** and it *adds* personalization while *removing* friction — the only move that wins on both axes.

**P3 — `planning_party` (screen 17). Cut it — but as an A/B, not a deletion.**
The only question whose answer is **never used**: `OnboardingData.party` is set by `OnboardingPartyScreen` and read nowhere — not passed to `DataManager.createWeddingWithDetails`, not used by `OnboardingChecklist.tasks`, not persisted. Verified by grep across the target. It also sits in the worst position: the last ask before the payoff, where tolerance is lowest.
⚠️ **The Lose It! finding argues unused questions still lift trial starts** — this cut contradicts the single strongest pro-length datapoint we have. It is one screen behind a flag. **Flag it 50/50 and let it settle the argument** rather than deciding by opinion.

**P4 — Three preview screens → two.** `preview_checklist` / `preview_budget` / `preview_guests` is the flattest stretch in the flow: three consecutive tap-throughs showing *product* rather than *her plan*. Guests is weakest (the guest question was a 5-way band; least personal content to show back). Fold it into the checklist preview.

**P5 — Endowed progress on the bar.** The code deliberately never renders "3 of 26" — correct. Go further: Nunes & Drèze got **34% vs 19%** completion by pre-filling 2 of 10 stamps versus a bare 8. Start the bar visibly non-zero (the welcome and social-proof screens already "count"), and segment it into three named sections — *about you · your plan · getting started* — so it completes a section rather than crawling 4% per tap. A bar that inches forward is a "this is long" signal by another route.

**P6 — Disable forward swipe.** The flow is a `TabView` with `PageTabViewStyle`; unless gestures are explicitly disabled, users can swipe forward and skip screens. On a 26-screen flow the impatient segment will speed-run past every payoff and arrive at the paywall with none of the persuasion. Confirm and lock.

**P7 — Paywall framing (adjacent, cheap).** We now hold her actual budget band from screen 11 — use *her* number in the "€49.99 against a €35,000 wedding" line, not a generic one. And per §1/point 5, the gate is survivable but **surprise is not**: the trial-end terms must be unmissable, and the trial-end reminder must actually fire (`MISSION-3X-ARPU.md` items 0.4/0.5 flag that it currently gets wiped). Every 1★ "scam" review in this category is about a surprise charge, not a price.

### Add — screens that would genuinely earn their place

Ranked by how visibly the answer changes the artifact she is shown. That is the only test worth applying.

**A1 — Ceremony type. The strongest single addition in this document.**
The checklist master in `OnboardingChecklist.swift` is 27 tasks hard-coding one wedding: *"Confirm your officiant"*, *"Taste and order the cake"*, *"Collect your marriage paperwork"*. There is **no ceremony-type branching at all**. A German user gets no Standesamt task. A Muslim user gets no nikah/mahr step. A Hindu user gets no multi-day structure. A civil-only couple gets an officiant task that means nothing. One tap — *Civil · Religious · Both · Not decided*, plus a tradition follow-up where relevant — forks the checklist materially, and its payoff screen writes itself: *"We've added the four paperwork steps German couples always forget."* This makes the product genuinely better **and** makes the reveal more credible, which is the constraint identified in §2c. **Do this one.**

**A2 — Partner / co-planner invite, before the paywall.**
Ask for the partner's contact and offer to send them the plan. Three things at once: a commitment act stronger than hold-to-commit (it involves another person — this is Freedman & Fraser's foot-in-the-door with real stakes), a retention asset (two people in a plan churn less than one), and it turns "the two of us" into an actual product state rather than a discarded answer. **Only add if we ship shared/invite functionality** — otherwise it is a lie, and worse than nothing.

**A3 — One free-response or 3-option "what would make this wedding a success", quoted verbatim on the paywall.**
Not another taxonomy question. One emotionally-loaded answer printed above the price on the highest-value surface in the app. One screen.

**Explicitly NOT recommended:** style/vibe quiz (nothing in the product consumes it — The Knot's exists to match vendors, which we don't sell); city/region (only earns a slot if we ship regional budget benchmarking — Bridebook's "thousands of couples' actual spending" is exactly that, and it is a product feature first); photo upload (a permission prompt and a failure mode mid-flow for a cosmetic payoff).

---

## 5. What we genuinely don't know, and what would settle it

We are about to hold the data nobody publishes. `onboarding_step` fires per screen with a stable slug (`OnboardingFlowModel.swift` — the slugs are frozen deliberately; do not renumber them). Once live:

| Open question | What settles it |
|---|---|
| **What is our completion rate?** This is the one that governs everything. The IKEA effect only pays out on **successful completion**; every abandoner takes the cost and none of the benefit. Lengthening a flow with an unmeasured completion rate is the specific mistake the research warns against. | `welcome` → `value_recap` retention on the slug funnel. **Until this number exists, do not lengthen anything.** |
| **Where do people actually leave?** No published per-screen benchmark exists for any app, anywhere. Our own curve is the only real evidence we will ever have. | Drop-off by slug. **Prediction on record so it can be checked:** the worst three will be `venue` (keyboard, no payoff), `planning_party` (last ask before the payoff), and one of the three `preview_*` screens. |
| **How long does it actually take?** My "2.5–4 minutes" is an estimate from the screen inventory and the one hard-coded duration, **not a measurement.** | Timestamp deltas between consecutive `onboarding_step` events → median seconds/screen and total time-to-paywall. **Seconds-to-paywall is the real variable; screens are a proxy.** |
| **Does length help or hurt us?** Nothing published answers this for any category, let alone ours. | The only clean test, and it should probe **upward**: 26 vs ~35 (add A1 + A2 + more mid-flow social proof), not 26 vs 16. Run it **after** the current build has a baseline and **not** simultaneously with the pricing flip — two changes at once and we learn nothing. |
| **Does the unused-question effect (Lose It!) replicate at our scale?** The crux of P3. | Flag `planning_party` on/off 50/50. One screen, one flag, settles a real disagreement in the evidence. |
| **Loader duration.** Buell & Norton says longer-with-visible-work wins; Adapty reports an app that gained +22% trial by deleting the loader entirely. Genuinely unresolved. | 3.5s vs 6s vs 10s, holding the legibility change constant. |
| **Traffic-source interaction.** Unsourced inference. | Segment the same drop-off curve by Singular attribution source (ASA / Meta / organic). If organic drops off harder through the question block, that is a genuine finding and worth a shorter organic variant. |
| **Is onboarding even the constraint?** | Instrument `paywall_view` with a trigger-source property (already planned, `MISSION-3X-ARPU.md` 0.7). **If install→paywall_view is already above ~80%, onboarding length is not the bottleneck** and further work here is rounding-error against the pricing and gate changes. |

**Be honest about power.** At ~93 US ratings we almost certainly cannot reach significance on a 3-arm length test quickly. The realistic sequence: ship P1/P2/A1 (none of which needs a test), get the baseline drop-off and completion curve, and only spend statistical power on the length question if the curve shows a cliff. If it doesn't, 26 is fine and the leverage is elsewhere — which, per `MISSION-3X-ARPU.md`, it almost certainly is. **The price tier and the gate are worth multiples of anything in this document, and the App Store category being "Utilities" is probably worth more than both.**

---

## Sources

**Datasets & benchmarks**
- [PaywallPro open paywall gallery (960 apps)](https://github.com/paywallpro/paywall-gallery) — screen-count distribution computed from `apps/index.md`
- [RevenueCat — State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps) · [2025](https://www.revenuecat.com/state-of-subscription-apps-2025) · [2024](https://www.revenuecat.com/state-of-subscription-apps-2024/) · [10-min summary](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026/)
- [RevenueCat — Why your onboarding experience might be too short](https://www.revenuecat.com/blog/growth/why-your-onboarding-experience-might-be-too-short/) · [Fix your onboarding funnel first](https://www.revenuecat.com/blog/growth/fix-onboarding-funnels/) · [Lessons from Lose It!](https://www.revenuecat.com/blog/growth/50-million-users-5-key-strategies-lessons-from-lose-it/)
- [Superwall — Multi-page onboarding paywalls convert 37% better](https://superwall.com/blog/new-postmulti-page-onboarding-paywalls-convert-37-better-than-single-page-heres-why) *(vendor)*
- [Adapty — State of In-App Subscriptions 2026](https://adapty.io/blog/mobile-app-monetization-2026/) · [High-performing paywall 2026](https://adapty.io/blog/high-performing-paywall-2026/) · [7 onboarding best practices](https://adapty.io/blog/how-to-fix-your-onboarding-flow/) · [Apple Ads install-to-paid benchmarks](https://adapty.io/blog/apple-ads-install-to-paid-rate-benchmarks/) *(all vendor)*
- [Baymard — checkout flow / form fields](https://baymard.com/blog/checkout-flow-average-form-fields)
- Screen-count galleries: [reteno](https://gallery.reteno.com/) · [tasu](https://tasu.ai/library) · [onbo-hub](https://onbo-hub.com/) · [theappfuel](https://theappfuel.com/) — *all curated for long flows; selection-biased by design*

**Primary research**
- Buell & Norton, [The Labor Illusion](https://pubsonline.informs.org/doi/10.1287/mnsc.1110.1376), *Management Science* 57(9), 2011
- Freedman & Fraser, [Compliance without pressure: the foot-in-the-door technique](https://web.mit.edu/curhan/www/docs/Articles/15341_Readings/Influence_Compliance/Freedman_Fraser_Foot-in-the-door.pdf), *JPSP* 4(2), 1966
- Aronson & Mills, [The effect of severity of initiation on liking for a group](https://web.mit.edu/curhan/www/docs/Articles/15341_Readings/Motivation/Aronson_Mills_1959_The_effect_of_severity_of_initiation.pdf), 1959
- Norton, Mochon & Ariely, [The IKEA effect](https://myscp.onlinelibrary.wiley.com/doi/abs/10.1016/j.jcps.2011.08.002), *J. Consumer Psychology* 22(3), 2012
- Nunes & Drèze, [The endowed progress effect](https://academic.oup.com/jcr/article-abstract/32/4/504/1787425), *JCR* 32(4), 2006
- Lala & Chakraborty, *J. Consumer Marketing* 32(2), 2015, [DOI](https://doi.org/10.1108/JCM-08-2014-1090)
- Sunk cost over time — [2023 registered replication, *IRSP*](https://rips-irsp.com/articles/10.5334/irsp.883)

**Competitors**
- [The Knot](https://apps.apple.com/us/app/the-knot-wedding-planner/id457941553) · [Zola](https://apps.apple.com/us/app/zola-wedding-planner/id852691916) · [Joy](https://withjoy.com/pricing/) · [Bridebook cost](https://support.bridebook.com/en/support/how-much-does-bridebook-cost) · [Appy Couple](https://apps.apple.com/us/app/appy-couple-wedding-app/id492345619) · [Minted](https://www.minted.com/ido)
- App Store category, IAP and review data via the iTunes Search/Lookup API and Apple's customer-reviews RSS feed
