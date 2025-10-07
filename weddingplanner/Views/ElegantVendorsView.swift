import SwiftUI

struct ElegantVendorsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Vendors")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "4A4A4A"))
                    .padding(.top, 20)
                
                // Placeholder elegant cards
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.7))
                        .frame(height: 120)
                        .shadow(color: PastelColors.peach.opacity(0.1), radius: 20, y: 10)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }
}

struct ElegantVendorsView_Previews: PreviewProvider {
    static var previews: some View {
        ElegantVendorsView()
    }
}