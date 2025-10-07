import SwiftUI

struct ModernGuestsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Guests")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Placeholder content
                ForEach(0..<5) { _ in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .frame(height: 100)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 100)
        }
    }
}

struct ModernGuestsView_Previews: PreviewProvider {
    static var previews: some View {
        ModernGuestsView()
    }
}