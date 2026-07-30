# Pricing Flip Runbook — Phase 1, Mission 3x ARPU

**Owner: human (Deyar).** The code side is done and shipped (Phase 1 commit). Everything in this
document happens in **App Store Connect** and the **RevenueCat dashboard** — no agent touches
either. The app reads whatever the `default` RevenueCat offering contains, so the flip is a
dashboard change, reversible, and affects new cohorts only (existing subscribers keep their price).

Expected effect (from `MISSION-3X-ARPU.md`): **+40–70% RPD**, $0.62 → ~$1.0–1.1 from this step alone.

---

## 0. Ground truth as of 2026-07-30 (pulled read-only from the ASC API)

| | |
|---|---|
| App | **Wedding Planner: BridePlan** |
| Bundle ID | `com.manuelworlitzer.weddingplanner` |
| **ASC App ID** | **`6753721577`** (note: the `6748553668` in `~/.claude/CLAUDE.md` is a *different* app) |
| **Subscription group** | **`21802664`** — reference name "Wedding Planner Premium" |
| RevenueCat entitlement | `premium` |
| RevenueCat public SDK key | `appl_vjZKEFBMhudkcRJzNaBjnzSbfUC` (`Config.swift`) |

### Live products today

| productId | ASC id | Period | State | US | DE | Intro offer | Group level |
|---|---|---|---|---|---|---|---|
| `…premium.weekly` | 6753861211 | 1 week | APPROVED | **$7.99** | **€7.99** | **3-day free trial**, all 175 territories, active since 2025-10-16 | 2 |
| `…premium.6months` | 6753861065 | 6 months | APPROVED | $29.99 | €29.99 | none | 1 (top) |

**The $4.99 vs $7.99 discrepancy is resolved.** The weekly product carries two price-schedule
entries per territory: `$4.99 / €4.99` with `preserved: true` and no start date (grandfathered —
applies only to people who subscribed before the raise), and `$7.99 / €7.99` with
`startDate: 2026-06-23` (the live price for every new customer). **Current customer-facing weekly
price is $7.99 / €7.99.** The audit's $4.99 figure is the pre-June-23 price; any ARPU/LTV math
still using $4.99 is stale. Proceeds at $7.99: $6.79 US / €5.71 DE.

Also present, **not live, do not use**: `com.manuelworlitzer.weddingplanner.premium.6monthsOnetime`
(ASC id 6754212769, NON_CONSUMABLE, state `MISSING_METADATA`, no price schedule). It is an
abandoned draft. Either finish deleting it or leave it — it must not end up in an offering.

No promotional offers and no win-back offers exist on either product yet.

---

## 1. App Store Connect — create the three new SKUs

Two go into the **existing** subscription group `21802664` ("Wedding Planner Premium"). The
"Forever" SKU is **not** a subscription — it is a non-consumable in-app purchase.

### 1a. Annual subscription

| Field | Value |
|---|---|
| Reference name | `Wedding Planner Premium Yearly` |
| **Product ID** | `com.manuelworlitzer.weddingplanner.premium.annual` |
| Subscription group | **Wedding Planner Premium (21802664)** |
| Duration | 1 year |
| Price US | **$49.99** |
| Price DE | **€59.99** |
| Display name | `Yearly` |
| Description | `Full access to every planning tool until your wedding day.` |
| **Group level** | **1 (top)** — push 6-month to 2, weekly to 3 |
| Free trial | see §1d |

### 1b. Monthly subscription (decoy — never the default)

| Field | Value |
|---|---|
| Reference name | `Wedding Planner Premium Monthly` |
| **Product ID** | `com.manuelworlitzer.weddingplanner.premium.monthly` |
| Subscription group | **Wedding Planner Premium (21802664)** |
| Duration | 1 month |
| Price US | **$12.99** |
| Price DE | **€14.99** |
| Display name | `Monthly` |
| Group level | below annual and 6-month |
| Free trial | **none** — the trial belongs on annual only |

### 1c. Forever (non-consumable, NOT in the subscription group)

App Store Connect → Monetization → **In-App Purchases** → `+` → **Non-Consumable**.

| Field | Value |
|---|---|
| Reference name | `Wedding Planner Premium Forever` |
| **Product ID** | `com.manuelworlitzer.weddingplanner.premium.lifetime` |
| Type | Non-Consumable |
| Price US | **$79.99** |
| Price DE | **€99.99** |
| Display name | `Forever` |
| Description | `Pay once. Every planning tool, yours until the big day and beyond.` |

Each product needs a review screenshot of the paywall + a review note before it leaves
`MISSING_METADATA`. All three must reach **Ready to Submit / Approved** before RevenueCat can
serve them.

### 1d. Free trial on annual

Set an **introductory offer → Free trial** on the annual product, **all territories**, duration
per the A/B arm you are testing (§3). If you are starting with the trial arm, use **14 days**
(the plan's favourite: 17–32d trials convert 42.5% trial→paid vs 25.5% at ≤4d). The app reads the
trial length off the product's introductory offer — **do not** hardcode anything, and do not
assume 3 days; that number now only survives as an offline fallback in `Config.fallbackTrialDays`
for the split second before offerings load.

### 1e. Territory prices beyond US/DE

Do **not** hand-set 175 territories. Set US as base, then roll the EU/UK/CH/CA factors with the
`/asc-pricing` skill (localization tests have the highest win rate of any test class, 62.3%; DE
carries the highest median monthly price worldwide). This is a separate pass **after** the ladder
is live and verified in US + DE.

### 1f. Do NOT touch the existing SKUs

Leave `…premium.weekly` at $7.99 and `…premium.6months` at $29.99, both APPROVED. They stop being
sold on the main paywall (they simply leave the `default` offering) and become the Phase 4
recovery inventory: weekly = rescue SKU, 6-month = dismissal discount. Existing subscribers are
untouched either way.

---

## 2. RevenueCat — attach products, rebuild the `default` offering

### 2a. Products

RevenueCat → **Products** → `+ New` → App Store → paste each product ID exactly:

- `com.manuelworlitzer.weddingplanner.premium.annual`
- `com.manuelworlitzer.weddingplanner.premium.lifetime`
- `com.manuelworlitzer.weddingplanner.premium.monthly`

They will not import until ASC shows them as at least "Ready to Submit". Confirm each product
imports with a price — a product showing no price is not fetchable by the SDK either.

### 2b. Entitlement

Attach all three to the **existing `premium` entitlement**. Do not create a new entitlement —
`SubscriptionManager.isSubscribed` checks `premium` and nothing else. A product not attached here
purchases fine and unlocks nothing.

### 2c. The `default` offering

Offerings → `default` (create it if the project genuinely has none — the audit found no offering
ID configured, which is why no A/B was possible). Add exactly three packages:

| Package identifier | Package type | Product |
|---|---|---|
| `$rc_annual` | **Annual** | `…premium.annual` |
| `$rc_lifetime` | **Lifetime** | `…premium.lifetime` |
| `$rc_monthly` | **Monthly** | `…premium.monthly` |

**The package *type* is what matters, not the product ID.** The app orders, labels, badges and
pre-selects cards purely from package type (`SubscriptionManager.PlanKind`):

- **Annual** → rendered first, pre-selected, "BEST VALUE" badge, headline price shown as the
  per-week equivalent (~$0.96/week at $49.99) computed from the product's own price and period.
- **Lifetime** → second, subtitle "Pay once, yours until the big day & beyond", caption "one-time".
- **Monthly** → third, no badge, never pre-selected.

If you attach the annual product to a *custom* package instead of `$rc_annual`, the app falls back
to reading the StoreProduct's subscription period and still classifies it correctly — but use the
standard identifiers anyway.

Mark `default` as the **Current** offering. That is the flip. No app release required.

### 2d. Ordering / safety

Ship order matters: **create in ASC → attach in RC → build the offering → only then set it
current.** Making an offering current while a product is still `MISSING_METADATA` yields a paywall
with missing cards. The paywall degrades gracefully (it renders whatever exists, and shows a
spinner if the offering is empty), but a one-card paywall is a bad day of revenue.

**Rollback:** set the old offering back to Current. One click, instant, no release.

---

## 3. Trial A/B (do this *after* the ladder is verified live)

The trial-structure test has the highest win rate of any test class (59.6%) — it is the most
valuable single test in the mission. It runs entirely in RevenueCat; the app already supports both
arms without a rebuild.

1. Duplicate the annual product in ASC? **No.** Duplicate the *offering* instead:
   - `default` → annual **with** the 14-day free trial
   - `no_trial` → an offering whose annual package points at an annual product **without** an
     introductory offer (this does require a second ASC product, e.g.
     `…premium.annual.notrial`, since the intro offer lives on the product)
2. RevenueCat → **Experiments** → new experiment, control `default` vs. treatment `no_trial`,
   50/50.
3. The paywall reads trial presence per-package off the introductory offer and switches copy by
   itself:
   - trial arm → card subtitle "14 days free, then $49.99/year", CTA "Start Planning Together",
     trust line "No payment due now"
   - no-trial arm → card subtitle "$49.99/year", CTA **"Unlock everything"**, trust line "Cancel
     anytime, no commitment"
   - lifetime card → "Pay once, yours until the big day & beyond", trust line "One payment, no
     subscription"
4. Decide on **revenue per user, never conversion alone**. Minimum 200 subscriptions per variant;
   pricing/trial tests need a 3-month window to absorb refunds and first renewals.

A third arm (paid trial $1.99/7d) is in the plan but is a later, separate test — don't run three
arms on this traffic volume.

---

## 4. Verification checklist — nothing is "done" until all of these pass

Reported state must match real state. Tick every line.

**App Store Connect**
- [ ] All three new products show **Approved / Ready to Submit**, not `MISSING_METADATA`.
- [ ] Annual: US $49.99 / DE €59.99. Lifetime: US $79.99 / DE €99.99. Monthly: US $12.99 / DE €14.99.
- [ ] Annual carries the free trial, all territories, for the intended duration.
- [ ] Group levels: annual on top, then 6-month, then weekly. Monthly below annual.
- [ ] Weekly still $7.99/€7.99 and 6-month still $29.99/€29.99 — unchanged.

**RevenueCat**
- [ ] All three products imported **with prices**.
- [ ] All three attached to the **`premium`** entitlement.
- [ ] `default` offering has exactly `$rc_annual`, `$rc_lifetime`, `$rc_monthly` and is **Current**.
- [ ] RC → Customer History on a test user shows the offering being served.

**In the app (sandbox, real device)**
- [ ] Paywall shows **three** cards, order Yearly → Forever → Monthly.
- [ ] **Yearly is pre-selected on open** and carries the "BEST VALUE" badge.
- [ ] Yearly headline shows the **per-week** figure (~$0.96 / ~€1.15), not the yearly price.
- [ ] Trial copy matches the actual introductory offer (say "14 days free", not "3 days").
- [ ] Sandbox-purchase the **annual** → entitlement `premium` goes active, paywall dismisses,
      premium features unlock, trial reminders are cancelled.
- [ ] Sandbox-purchase the **lifetime** → same, and the copy says one-time, not subscription.
- [ ] **Restore Purchases** works on a second install.
- [ ] Analytics: `paywall_plan_selected` fires with `plan=annual|lifetime|monthly` on tap.

**Locale check (this is where the old paywall was broken)**
- [ ] Device set to **de-DE / German**: every price renders in **€ with German formatting**
      (`59,99 €`), the per-week line included. No `$` anywhere on the paywall.
- [ ] Card labels read `Jährlich` / `Für immer` / `Monatlich`, badge `BESTES ANGEBOT`, subtitle
      `14 Tage gratis, danach 59,99 €/Jahr`.
- [ ] Spot-check one more locale (fr or it) for layout overflow on the card rows.

**Live, after the flip**
- [ ] RC dashboard shows real purchases landing on the annual product within 24h.
- [ ] Watch **rating velocity + keyword rank weekly** — organic is the traffic motor and the only
      thing that can seriously break.

---

## 5. Decisions the human owns before flipping

1. **Trial length on annual**: 14 days (plan's recommendation) vs. keeping 3. Whatever is set in
   ASC is what the app displays — the app no longer has an opinion.
2. **Which arm ships as `default`** at flip time (trial vs. no-trial), and whether the A/B starts
   immediately or after a clean baseline week on the new prices.
3. **Grandfathering**: current weekly/6-month subscribers keep their price automatically. Confirm
   you do *not* want a migration offer for them.
4. **Ship order**: the app build works today against the *old* offering too — it renders weekly +
   6-month gracefully — but it will pre-select the **6-month** plan (highest-value plan present)
   instead of weekly. If the binary reaches users before the RC flip, the default selection has
   already moved from weekly to 6-month. That is directionally what the plan wants, but it is a
   live pricing behaviour change, so it is your call, not the code's.
5. Whether to finish deleting the stale `…premium.6monthsOnetime` draft IAP.

---

## 6. Phase 4 store-side — recovery surfaces

**Owner: human.** The code for all three recovery surfaces is shipped (Phase 4 commit). Two of the
three do nothing at all until the RevenueCat side below exists — deliberately: each one checks for
its offering/package and **skips silently** when it is missing, so the binary is safe to ship
before the flip and nobody meets a broken sheet.

| Surface | Trigger | Needs store-side |
|---|---|---|
| **Dismissal paywall** (decline ladder) | user closes the main paywall without buying, source `post_onboarding` or `cold_start` only, max 1×/7d, never twice per session, never for premium | **RC offering `dismissal`** — without it: no-op |
| **Post-purchase Forever upsell** | immediately after a *subscription* purchase, once per user ever | **a lifetime package in the `default` offering** (§2c) — without it: no-op |
| **T-60 win-back** | local notification 60 days before the wedding date, non-premium users only, 10:00 local | **nothing** — works today |

### 6a. RevenueCat offering `dismissal`

Offerings → `+ New` → identifier **`dismissal`**. Do **not** mark it Current — the app fetches it
by identifier (`RecoveryOffers.dismissalOfferingID`), `current` stays the main paywall.

The recovery inventory is the two SKUs that leave the main paywall in Phase 1 (§1f) — both are
already APPROVED, so no ASC work is needed:

| Package identifier | Package type | Product | Role |
|---|---|---|---|
| `$rc_six_month` | **6 Month** | `…premium.6months` ($29.99 / €29.99) | discount anchor — 40% under annual, the "once you close this, it's gone" offer |
| `$rc_weekly` | **Weekly** | `…premium.weekly` ($7.99 / €7.99) | rescue SKU — lowest possible entry price for a hard decliner |

Both must be attached to the **`premium`** entitlement (they already are — same entitlement as
everything else; verify, do not re-create).

The sheet renders whatever this offering contains, in the same order the main paywall uses
(longest commitment first), with **no** "BEST VALUE" badge and **no** invented discount claims. So
the shape is a dashboard decision:

- **Both packages** (recommended start): a real ladder — take the 6-month, or drop to weekly.
- **6-month only**: cleanest "last chance" discount, no cheap escape hatch, protects LTV.
- **Weekly only**: maximum recovery rate, lowest LTV per recovery. Only if the two-card version
  under-converts.
- **Delete the offering**: the surface switches itself off. That is the rollback — one click, no
  release.

> **No fake anchors.** The code deliberately shows no struck-through "was $49.99" price. The
> discount is real (the 6-month is genuinely cheaper than the annual) but the two SKUs have
> different durations, so a crossed-out comparison would be a misleading claim and an App Store
> 3.1.2 risk. If you want an explicit anchor later, the honest version is a *same-duration*
> discounted product with a promotional offer — that is an ASC change, not a copy change.

### 6b. Forever upsell — no new store-side work

It uses the **lifetime package of the `default` offering** (`$rc_lifetime`, §2c). If Phase 1's
ladder is live, this surface is already armed. If you ship the ladder without a lifetime SKU, the
upsell silently never appears — no error state.

**Decision you own:** buying Forever does **not** cancel the subscription the user started thirty
seconds earlier — StoreKit cannot do that, only the user can. The screen therefore carries the line
*"Your current plan stays active until you cancel it in the App Store."* Removing that line will
lift take-rate and buy you refund requests and 1-star reviews. Leave it.

### 6c. Win-back — local notification, no ASC offer

The T-60 win-back is a **local notification**, not an App Store win-back offer. That is the point:
we know the wedding date, so we can hit the highest-intent moment in the category (start of panic
season) without any store-side configuration, and it reaches people who *never subscribed* — whom
an ASC win-back offer cannot touch at all (those are for **lapsed subscribers** only).

Requires notification permission, which is asked for in the primed onboarding screen. Users who
denied it get nothing — that is the cost of the opt-in rate, not a bug.

**Later option (not built):** an **ASC win-back offer** on the subscription group for genuinely
lapsed subscribers (Monetization → Subscriptions → group `21802664` → Win-Back Offers). Churned-
monthly reactivation runs ~20% in the category. It is a separate lever from this one, it needs its
own price/duration decision, and RevenueCat surfaces it through the standard offering machinery —
so it is additive, not a replacement. Revisit once there is a meaningful lapsed base.

### 6d. Verification checklist — Phase 4

**Dismissal paywall (sandbox, real device, free user)**
- [ ] RC → Offerings shows `dismissal` with the intended packages, and `default` is still Current.
- [ ] Open the app cold as a free user → main paywall → tap **X** → the dismissal sheet appears.
- [ ] Prices on it are the **6-month / weekly** prices, in the device's currency and formatting
      (de-DE: `29,99 €`, no `$` anywhere).
- [ ] Close it → the whole paywall goes away, the app is usable. `dismissal_paywall_dismissed` fires.
- [ ] Open and close the main paywall **again in the same session** → the sheet does **not**
      reappear (session guard).
- [ ] Trigger the paywall from a **feature gate** (e.g. the 11th guest) and close it → the sheet
      does **not** appear. Feature gates are excluded on purpose.
- [ ] Delete the `dismissal` offering in RC → close the main paywall → nothing happens, no blank
      sheet, no spinner. (Then put it back.)
- [ ] Sandbox-purchase from the sheet → entitlement `premium` goes active,
      `dismissal_paywall_purchased` fires with `plan=six_month|weekly`.
- [ ] 7-day cap: reinstall (or clear `lastDismissalOfferAt` in UserDefaults) to see it again —
      without that it must stay away for a week.

**Forever upsell (sandbox)**
- [ ] Sandbox-purchase the **annual** on the main paywall → the congratulations screen appears
      immediately with the **lifetime** price, locale-correct.
- [ ] Skip it → paywall closes, premium is active. `forever_upsell_skipped` fires.
- [ ] Buy annual **again** on a fresh sandbox purchase in the same install → the screen does
      **not** reappear (once per user, ever).
- [ ] Buy the **lifetime** directly on the main paywall → the upsell does **not** appear.
- [ ] Remove `$rc_lifetime` from `default` → buy annual → no upsell, no error. (Then put it back.)
- [ ] Sandbox-purchase the lifetime *from* the upsell → `forever_upsell_purchased` fires,
      entitlement stays active.

**T-60 win-back (no store-side config needed)**
- [ ] As a **free** user, set the wedding date to **90 days** out → Xcode → Debug → the pending
      request `winback.t60` exists, firing at 10:00 exactly 60 days before that date. (Or:
      `po UNUserNotificationCenter.current().getPendingNotificationRequests` / the notification
      debugger.)
- [ ] Move the wedding date by a week → the pending request moves with it, and there is still
      exactly **one** `winback.t60`.
- [ ] Set the wedding date to **30 days** out → **no** `winback.t60` pending. A user already inside
      the final 60 days must not get "60 days to go".
- [ ] Purchase premium → `winback.t60` disappears. Trial reminders and the daily/weekly schedule
      are **untouched** (scoped identifiers — check the full pending list, not just this one).
- [ ] Fire the notification (change the device date or shorten the lead in a debug build) → tapping
      it opens the app **and** the paywall, and `paywall_view` carries `source=winback`.

**Analytics (all three)**
- [ ] Singular + Meta receive `dismissal_paywall_viewed|_purchased|_dismissed` and
      `forever_upsell_viewed|_purchased|_skipped`.
- [ ] `paywall_view` / `paywall_dismissed` now also appear with `source=winback`.
