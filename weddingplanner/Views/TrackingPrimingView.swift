import SwiftUI

/// Pre-permission priming sheet shown immediately before the system ATT prompt.
/// Warms the user up to raise the opt-in rate; the real consent is still Apple's
/// system dialog, triggered by `onContinue`. Styled to the app's CI.
struct TrackingPrimingView: View {
    let onContinue: () -> Void

    @State private var showSheet = false

    var body: some View {
        ZStack {
            // Same cream gradient as the onboarding screens — seamless transition.
            LinearGradient(
                colors: [Color(hex: "F8F4F0"), Color(hex: "F5EFE7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Scrim
            Color.black
                .opacity(showSheet ? 0.12 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.4), value: showSheet)

            VStack {
                Spacer()
                sheet
                    .offset(y: showSheet ? 0 : 600)
                    .animation(.spring(response: 0.55, dampingFraction: 0.85), value: showSheet)
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showSheet = true
            }
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: "D4B5A9").opacity(0.35))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            // Icon badge
            ZStack {
                Circle()
                    .fill(Color(hex: "D4B5A9").opacity(0.15))
                    .frame(width: 76, height: 76)
                Image(systemName: "heart.fill")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundColor(Color(hex: "D4B5A9"))
            }
            .padding(.top, 28)

            Text("One quick thing")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, 28)

            Text("We use tracking only to personalize your planning and keep this app free. You decide on the next screen.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "6B6B6B"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 10)
                .padding(.horizontal, 28)

            VStack(spacing: 18) {
                bullet(icon: "sparkles", tint: "D4B5A9",
                       text: "Tailored vendor & budget suggestions")
                bullet(icon: "gift.fill", tint: "C8D4C8",
                       text: "Helps keep the app free")
                bullet(icon: "lock.fill", tint: "9B9B9B",
                       text: "Your data is never sold")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "2C2C2C").opacity(0.035))
            )
            .padding(.top, 26)
            .padding(.horizontal, 28)

            Button(action: dismissAndContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
            }
            .padding(.top, 28)
            .padding(.horizontal, 28)

            Spacer(minLength: 28)
        }
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(Color(hex: "FFFDFB"))
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: -6)
        )
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 80 {
                        dismissAndContinue()
                    }
                }
        )
    }

    private func bullet(icon: String, tint: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: tint).opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: tint))
            }
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(hex: "2C2C2C"))
            Spacer(minLength: 0)
        }
    }

    private func dismissAndContinue() {
        withAnimation(.easeIn(duration: 0.25)) { showSheet = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onContinue()
        }
    }
}
