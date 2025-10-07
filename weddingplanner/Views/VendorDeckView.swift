import SwiftUI

struct VendorDeckView: View {
    @State private var vendors = VendorDeckCard.sampleVendors
    @State private var dragOffset = CGSize.zero
    @State private var activeCardIndex = 0
    @State private var likedVendors: Set<UUID> = []
    @State private var rejectedVendors: Set<UUID> = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background cards
                ForEach(vendors.indices.reversed(), id: \.self) { index in
                    if index >= activeCardIndex && index < activeCardIndex + 3 {
                        VendorCardView(
                            vendor: vendors[index],
                            geometry: geometry,
                            cardIndex: index - activeCardIndex,
                            dragOffset: index == activeCardIndex ? dragOffset : .zero,
                            onSwipe: { direction in
                                handleSwipe(direction: direction, at: index)
                            }
                        )
                    }
                }
                
                // Action indicators
                VStack {
                    Spacer()
                    
                    SwipeIndicators()
                        .padding(.bottom, 80)
                }
                
                // Category filters
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(VendorCategoryType.allCases, id: \.self) { category in
                                CategoryPill(category: category, isSelected: false)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if activeCardIndex < vendors.count {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        handleSwipeEnd(value: value)
                    }
            )
        }
    }
    
    func handleSwipeEnd(value: DragGesture.Value) {
        let threshold: CGFloat = 100
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if value.translation.width > threshold {
                handleSwipe(direction: .right, at: activeCardIndex)
            } else if value.translation.width < -threshold {
                handleSwipe(direction: .left, at: activeCardIndex)
            } else if value.translation.height < -threshold {
                handleSwipe(direction: .up, at: activeCardIndex)
            } else {
                dragOffset = .zero
            }
        }
    }
    
    func handleSwipe(direction: SwipeDirection, at index: Int) {
        guard index < vendors.count else { return }
        
        let vendor = vendors[index]
        
        switch direction {
        case .left:
            rejectedVendors.insert(vendor.id)
        case .right:
            likedVendors.insert(vendor.id)
        case .up:
            // Super like - book immediately
            likedVendors.insert(vendor.id)
        }
        
        withAnimation(.spring()) {
            activeCardIndex += 1
            dragOffset = .zero
        }
    }
}

enum SwipeDirection {
    case left, right, up
}

enum VendorCategoryType: String, CaseIterable {
    case all = "All"
    case venue = "Venue"
    case photo = "Photo"
    case catering = "Catering"
    case flowers = "Flowers"
    case music = "Music"
    case beauty = "Beauty"
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .venue: return .blue
        case .photo: return .purple
        case .catering: return .orange
        case .flowers: return .pink
        case .music: return .green
        case .beauty: return .red
        }
    }
}

struct VendorDeckCard: Identifiable {
    let id = UUID()
    let name: String
    let category: VendorCategoryType
    let price: String
    let rating: Double
    let image: String
    let availability: String
    let portfolio: [String]
    
    static let sampleVendors = [
        VendorDeckCard(name: "Enchanted Gardens", category: .venue, price: "$8,000", rating: 4.9, image: "building.columns", availability: "3 dates left", portfolio: ["photo1", "photo2"]),
        VendorDeckCard(name: "Lens & Light Studio", category: .photo, price: "$3,500", rating: 4.8, image: "camera", availability: "Available", portfolio: ["photo3", "photo4"]),
        VendorDeckCard(name: "Bloom Artistry", category: .flowers, price: "$2,200", rating: 5.0, image: "leaf", availability: "Booking fast", portfolio: ["photo5", "photo6"]),
        VendorDeckCard(name: "Gourmet Affairs", category: .catering, price: "$12,000", rating: 4.7, image: "fork.knife", availability: "Available", portfolio: ["photo7", "photo8"]),
        VendorDeckCard(name: "DJ Euphoria", category: .music, price: "$1,800", rating: 4.9, image: "music.note", availability: "2 dates left", portfolio: ["photo9", "photo10"])
    ]
}

struct VendorCardView: View {
    let vendor: VendorDeckCard
    let geometry: GeometryProxy
    let cardIndex: Int
    let dragOffset: CGSize
    let onSwipe: (SwipeDirection) -> Void
    
    @State private var showDetails = false
    
    var cardOffset: CGSize {
        CGSize(
            width: dragOffset.width,
            height: dragOffset.height + CGFloat(cardIndex * 8)
        )
    }
    
    var cardRotation: Double {
        Double(dragOffset.width / 20)
    }
    
    var cardScale: CGFloat {
        1 - CGFloat(cardIndex) * 0.05
    }
    
    var opacity: Double {
        if cardIndex == 0 {
            return 1 - Double(abs(dragOffset.width) / 200)
        }
        return 1
    }
    
    var swipeIndicatorOpacity: Double {
        let threshold: CGFloat = 50
        if dragOffset.width > threshold {
            return Double((dragOffset.width - threshold) / 100)
        } else if dragOffset.width < -threshold {
            return Double((abs(dragOffset.width) - threshold) / 100)
        }
        return 0
    }
    
    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [vendor.category.color, vendor.category.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 0) {
                // Image area
                ZStack {
                    Rectangle()
                        .fill(vendor.category.color.opacity(0.2))
                    
                    Image(systemName: vendor.image)
                        .font(.system(size: 80))
                        .foregroundColor(vendor.category.color)
                }
                .frame(height: geometry.size.height * 0.5)
                
                // Info area
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vendor.category.rawValue.uppercased())
                                .font(.caption)
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(vendor.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                ForEach(0..<5) { star in
                                    Image(systemName: star < Int(vendor.rating) ? "star.fill" : "star")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            Text(vendor.price)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Availability badge
                    HStack {
                        Image(systemName: "calendar")
                        Text(vendor.availability)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        ActionButton(
                            icon: "photo.stack",
                            title: "Portfolio",
                            color: .white.opacity(0.9)
                        )
                        
                        ActionButton(
                            icon: "message",
                            title: "Message",
                            color: .white.opacity(0.9)
                        )
                        
                        ActionButton(
                            icon: "calendar.badge.plus",
                            title: "Book",
                            color: .white
                        )
                    }
                }
                .padding(24)
                .background(Color.black.opacity(0.2))
            }
            
            // Swipe indicators
            if dragOffset.width > 50 {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding()
                        .opacity(swipeIndicatorOpacity)
                    Spacer()
                }
            }
            
            if dragOffset.width < -50 {
                HStack {
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .padding()
                        .opacity(swipeIndicatorOpacity)
                }
            }
        }
        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.7)
        .offset(cardOffset)
        .rotationEffect(.degrees(cardRotation))
        .scaleEffect(cardScale)
        .opacity(opacity)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .foregroundColor(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.2))
        )
    }
}

struct CategoryPill: View {
    let category: VendorCategoryType
    let isSelected: Bool
    
    var body: some View {
        Text(category.rawValue)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color.gray.opacity(0.2))
            )
    }
}

struct SwipeIndicators: View {
    var body: some View {
        HStack(spacing: 40) {
            SwipeHint(icon: "xmark", color: .red, text: "Pass")
            SwipeHint(icon: "arrow.up", color: .purple, text: "Super")
            SwipeHint(icon: "heart", color: .green, text: "Love")
        }
        .padding()
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

struct SwipeHint: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}


struct VendorDeckView_Previews: PreviewProvider {
    static var previews: some View {
        VendorDeckView()
            .background(Color.black)
    }
}