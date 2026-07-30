import SwiftUI

// MARK: - Upsell sheet
//
// The one place a free user meets a limit. It never blocks silently: it names
// what was hit, says what Premium changes in a single warm line, and hands off
// to the real paywall. Everything routes through `PremiumGate`, so the copy and
// the analytics slug can never drift apart.

struct PremiumUpsellSheet: View {
    let gate: PremiumGate
    /// Called when the user taps the CTA — the host presents the paywall.
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: "E0E0E0"))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F6E7E1"), Color(hex: "EFDCD3")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: gate.icon)
                        .font(.system(size: 26, weight: .light))
                        .foregroundColor(Color(hex: "B89B91"))
                }

                VStack(spacing: 10) {
                    Text(gate.title)
                        .font(.system(size: 21, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .multilineTextAlignment(.center)

                    Text(gate.message)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "7A7A7A"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)

                VStack(spacing: 10) {
                    Button(action: onUnlock) {
                        Text("Unlock everything for your big day")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "D4B5A9"), Color(hex: "B89B91")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }

                    Button(action: { dismiss() }) {
                        Text("Not now")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))
                            .padding(.vertical, 6)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 26)
            .padding(.bottom, 20)

            Spacer(minLength: 0)
        }
        .background(Color(hex: "FDFBF7").ignoresSafeArea())
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Presentation modifier

/// Attaches the upsell sheet + paywall hand-off to a view. Set the bound gate
/// to a non-nil value from any blocked action:
///
///     Button { if dataManager.canAddGuest() { … } else { activeGate = .guestsLimit } }
///         .premiumUpsell($activeGate)
private struct PremiumUpsellModifier: ViewModifier {
    @Binding var gate: PremiumGate?
    @State private var pendingPaywallGate: PremiumGate?
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        content
            .sheet(item: $gate, onDismiss: {
                // The upsell sheet has to be gone before the paywall can take
                // over the screen, so the hand-off happens on dismissal.
                if pendingPaywallGate != nil {
                    showPaywall = true
                }
            }) { gate in
                PremiumUpsellSheet(gate: gate) {
                    pendingPaywallGate = gate
                    self.gate = nil
                }
            }
            .fullScreenCover(isPresented: $showPaywall, onDismiss: {
                pendingPaywallGate = nil
            }) {
                PaywallView(
                    isPresented: $showPaywall,
                    source: .featureGate,
                    gate: pendingPaywallGate
                )
                .environmentObject(SubscriptionManager.shared)
            }
    }
}

extension View {
    /// Presents the warm upsell sheet for `gate`, then the paywall.
    func premiumUpsell(_ gate: Binding<PremiumGate?>) -> some View {
        modifier(PremiumUpsellModifier(gate: gate))
    }
}

// MARK: - Lock affordances
//
// Locked things stay visible. A free user who can see the twelve budget
// categories they are not using knows exactly what they would be buying; a free
// user who sees nine categories thinks the app only has three.

/// Small "Premium" pill for a locked row, card or control.
struct PremiumLockBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: compact ? 8 : 9, weight: .semibold))

            if !compact {
                Text("Premium")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.5)
            }
        }
        .foregroundColor(Color(hex: "B89B91"))
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, compact ? 3 : 4)
        .background(
            Capsule().fill(Color(hex: "B89B91").opacity(0.12))
        )
    }
}

/// "7 of 10 free" style counter shown next to a limited list.
struct FreeLimitPill: View {
    let used: Int
    let limit: Int

    private var isFull: Bool { used >= limit }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isFull ? "lock.fill" : "person.crop.circle")
                .font(.system(size: 9, weight: .regular))

            Text("\(used) of \(limit) free")
                .font(.system(size: 10, weight: .regular))
        }
        .foregroundColor(isFull ? Color(hex: "B89B91") : Color(hex: "9B9B9B"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(isFull ? Color(hex: "B89B91").opacity(0.12) : Color(hex: "F0F0F0"))
        )
    }
}
