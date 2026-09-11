import SwiftUI

// MARK: - Palette

/// Everlens brand colours, kept local so the promo reads as Everlens inside
/// BridePlan's rose-gold world without leaking into the rest of the app.
private enum EverlensPalette {
    static let coral = Color(hex: "E0573C")
    static let coralLight = Color(hex: "F08A6E")
    static let cream = Color(hex: "FEF8EE")
}

// MARK: - Icon

/// The Everlens app icon, clipped like a home-screen icon.
struct EverlensIcon: View {
    let size: CGFloat

    var body: some View {
        Image("everlens-icon")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

// MARK: - Banner

/// Compact one-row entry point used inside task cards, the task sheet and the
/// vendors tab. Tapping it opens `EverlensPromoSheet`; the banner never links
/// out on its own so every install goes through the same pitch.
struct EverlensBanner: View {
    let surface: EverlensPromo.Surface
    var subtitle: LocalizedStringKey? = nil
    var compact: Bool = false

    @State private var showSheet = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showSheet = true
        } label: {
            HStack(spacing: compact ? 10 : 12) {
                EverlensIcon(size: compact ? 32 : 44)

                VStack(alignment: .leading, spacing: 3) {
                    if compact {
                        // Narrow task cards: brand on one line, pitch on the next.
                        Text(verbatim: "Everlens")
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("The disposable camera for your guests")
                            .font(.system(size: 12, weight: .thin))
                            .foregroundColor(Color(hex: "7A7A7A"))
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("Everlens: the disposable camera for your guests")
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .multilineTextAlignment(.leading)
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .thin))
                            .foregroundColor(Color(hex: "7A7A7A"))
                            .multilineTextAlignment(.leading)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(EverlensPalette.coral)
            }
            .padding(compact ? 10 : 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(EverlensPalette.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(EverlensPalette.coral.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showSheet) {
            EverlensPromoSheet(surface: surface)
        }
    }
}

// MARK: - Dashboard card

/// Wide card on the home tab for the last 60 days. Dismissable — a couple who
/// has guest photos handled should not see it again.
struct EverlensDashboardCard: View {
    let onDismiss: () -> Void

    @State private var showSheet = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            EverlensIcon(size: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "Everlens")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundColor(EverlensPalette.coral)

                Text("Give your guests a camera")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .multilineTextAlignment(.leading)

                Text("One QR code on every table and your wedding is captured from every angle.")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundColor(Color(hex: "7A7A7A"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        // Room for the close button so it never sits on the title.
        .padding(.trailing, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [EverlensPalette.cream, Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: EverlensPalette.coral.opacity(0.12), radius: 10, y: 4)
        )
        // One VoiceOver element for the card body — the close button below is
        // added after the merge, so it stays its own element.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { showSheet = true }
        // The close button must be a *descendant* of the view that carries the
        // tap gesture: a child Button beats its ancestor's gesture, whereas a
        // sibling Button layered on top (ZStack / overlay on a Button) loses
        // the tap to the card.
        .overlay(alignment: .topTrailing) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .padding(10)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(Text("Not now"))
            .accessibilityIdentifier("everlens.dismissCard")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            EverlensPromoSheet(surface: .dashboard)
        }
    }
}

// MARK: - Promo sheet

/// The pitch. Hero in Everlens coral, then BridePlan's serif voice: what it is,
/// how it works in three lines, one call to action. The App Store opens as an
/// in-app overlay so the couple stays where they were.
struct EverlensPromoSheet: View {
    let surface: EverlensPromo.Surface

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(hex: "FDFBF7")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero

                    VStack(spacing: 28) {
                        titleBlock
                        features
                        callToAction
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 24)
                }
            }
            .ignoresSafeArea(edges: .top)

            closeButton
                .padding(.top, 16)
                .padding(.trailing, 16)
        }
        .onAppear {
            Analytics.everlensPromoViewed(surface: surface.rawValue)
        }
    }

    // MARK: Sections

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [EverlensPalette.coral, EverlensPalette.coralLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft "flash" discs, echoing the disposable-camera idea.
            Circle()
                .fill(EverlensPalette.cream.opacity(0.10))
                .frame(width: 260, height: 260)
                .offset(x: -120, y: -90)
            Circle()
                .fill(EverlensPalette.cream.opacity(0.12))
                .frame(width: 180, height: 180)
                .offset(x: 130, y: 70)

            EverlensIcon(size: 104)
                .shadow(color: Color.black.opacity(0.18), radius: 18, y: 10)
                .padding(.top, 24)
        }
        .frame(height: 260)
        .clipped()
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            Text("Your wedding through your guests' eyes")
                .font(.system(size: 26, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))
                .multilineTextAlignment(.center)

            Text("Everlens turns every guest into a photographer. One QR code on the table — no app to download, no sign-up.")
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color(hex: "7A7A7A"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var features: some View {
        VStack(spacing: 18) {
            featureRow(
                icon: "qrcode",
                title: "Scan & shoot",
                body: "Guests scan the code and start snapping. iPhone guests open it instantly via App Clip."
            )
            featureRow(
                icon: "eye.slash",
                title: "The big reveal",
                body: "Photos stay hidden until you tap Reveal — like developing the film the morning after."
            )
            featureRow(
                icon: "photo.on.rectangle.angled",
                title: "One shared album",
                body: "Every photo lands in your album. Download them all and keep them forever."
            )
        }
    }

    private func featureRow(icon: String, title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(EverlensPalette.coral.opacity(0.10))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(EverlensPalette.coral)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text(body)
                    .font(.system(size: 13, weight: .thin))
                    .foregroundColor(Color(hex: "7A7A7A"))
                    .lineSpacing(2)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private var callToAction: some View {
        VStack(spacing: 14) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                EverlensPromo.openStore(from: surface)
            } label: {
                Text("Get Everlens — it's free")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [EverlensPalette.coral, EverlensPalette.coralLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: EverlensPalette.coral.opacity(0.25), radius: 10, y: 5)
            }

            Button {
                dismiss()
            } label: {
                Text("Not now")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }
            .accessibilityIdentifier("everlens.notNow")

            Text("By the makers of BridePlan")
                .font(.system(size: 11, weight: .thin))
                .foregroundColor(Color(hex: "B8B8B8"))
                .padding(.top, 4)
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(EverlensPalette.coral)
                .frame(width: 32, height: 32)
                .background(Circle().fill(EverlensPalette.cream.opacity(0.92)))
        }
        .accessibilityLabel(Text("Close"))
    }
}

#Preview("Sheet") {
    EverlensPromoSheet(surface: .task)
}

#Preview("Cards") {
    VStack(spacing: 24) {
        EverlensDashboardCard {}
        EverlensBanner(surface: .vendors, subtitle: "Your photographer gets the couple. Your guests get everything else.")
        EverlensBanner(surface: .timeline, compact: true)
    }
    .padding(24)
    .background(Color(hex: "F5F2EE"))
}
