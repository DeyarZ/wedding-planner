import SwiftUI

struct ElegantTimelineView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Timeline")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "4A4A4A"))
                    .padding(.top, 20)
                
                // Placeholder elegant cards
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.7))
                        .frame(height: 120)
                        .shadow(color: PastelColors.lavender.opacity(0.1), radius: 20, y: 10)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }
}

struct ElegantTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        ElegantTimelineView()
    }
}