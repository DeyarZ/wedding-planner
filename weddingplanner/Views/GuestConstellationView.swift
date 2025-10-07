import SwiftUI

struct GuestConstellationView: View {
    @State private var guests = GuestNode.sampleGuests
    @State private var selectedGuest: GuestNode? = nil
    @State private var draggedGuest: GuestNode? = nil
    @State private var showingAddGuest = false
    @State private var constellationScale: CGFloat = 1.0
    @State private var constellationOffset: CGSize = .zero
    @State private var animateConnections = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Starfield background
                StarfieldBackground()
                
                // Constellation connections
                ConstellationConnections(
                    guests: guests,
                    animate: animateConnections,
                    geometry: geometry
                )
                
                // Guest nodes
                ForEach(guests) { guest in
                    GuestNodeView(
                        guest: guest,
                        isSelected: selectedGuest?.id == guest.id,
                        isDragging: draggedGuest?.id == guest.id,
                        geometry: geometry,
                        onTap: { selectedGuest = guest },
                        onDrag: { isDragging in
                            if isDragging {
                                draggedGuest = guest
                            } else {
                                draggedGuest = nil
                            }
                        }
                    )
                    .position(guestPosition(for: guest, in: geometry))
                }
                
                // Controls overlay
                VStack {
                    HStack {
                        GroupFilterBar()
                        Spacer()
                        AddGuestButton { showingAddGuest = true }
                    }
                    .padding()
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    if selectedGuest != nil {
                        GuestDetailCard(guest: selectedGuest!) {
                            withAnimation(.spring()) {
                                selectedGuest = nil
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding()
                    }
                }
            }
            .scaleEffect(constellationScale)
            .offset(constellationOffset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        constellationScale = value
                    }
                    .simultaneously(with:
                        DragGesture()
                            .onChanged { value in
                                constellationOffset = value.translation
                            }
                    )
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1)) {
                    animateConnections = true
                }
            }
        }
    }
    
    func guestPosition(for guest: GuestNode, in geometry: GeometryProxy) -> CGPoint {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        // Position based on group and index
        let groupAngle = guest.group.angle
        let radius = guest.group.radius * min(geometry.size.width, geometry.size.height)
        
        let angle = groupAngle + (Double(guest.index) * 0.3)
        let x = centerX + cos(angle) * radius
        let y = centerY + sin(angle) * radius
        
        return CGPoint(x: x, y: y)
    }
}

struct GuestNode: Identifiable {
    let id = UUID()
    let name: String
    let group: GuestGroup
    let status: RSVPStatus
    let partySize: Int
    let index: Int
    let connections: [UUID]
    
    enum GuestGroup {
        case bride, groom, brideFamily, groomFamily, mutualFriends, work
        
        var color: Color {
            switch self {
            case .bride: return .pink
            case .groom: return .blue
            case .brideFamily: return .purple
            case .groomFamily: return .cyan
            case .mutualFriends: return .green
            case .work: return .orange
            }
        }
        
        var angle: Double {
            switch self {
            case .bride: return 0
            case .groom: return Double.pi
            case .brideFamily: return Double.pi / 3
            case .groomFamily: return 2 * Double.pi / 3
            case .mutualFriends: return 4 * Double.pi / 3
            case .work: return 5 * Double.pi / 3
            }
        }
        
        var radius: Double {
            switch self {
            case .bride, .groom: return 0.2
            case .brideFamily, .groomFamily: return 0.35
            case .mutualFriends, .work: return 0.45
            }
        }
    }
    
    static let sampleGuests: [GuestNode] = {
        let guest1 = UUID()
        let guest2 = UUID()
        let guest3 = UUID()
        
        return [
            GuestNode(name: "Sarah Johnson", group: .bride, status: .confirmed, partySize: 1, index: 0, connections: [guest2]),
            GuestNode(name: "Mike Smith", group: .groom, status: .confirmed, partySize: 1, index: 0, connections: [guest3]),
            GuestNode(name: "The Johnsons", group: .brideFamily, status: .confirmed, partySize: 4, index: 0, connections: []),
            GuestNode(name: "The Smiths", group: .groomFamily, status: .pending, partySize: 3, index: 1, connections: []),
            GuestNode(name: "Emma & Tom", group: .mutualFriends, status: .confirmed, partySize: 2, index: 0, connections: [guest1]),
            GuestNode(name: "Work Team", group: .work, status: .pending, partySize: 5, index: 0, connections: [])
        ]
    }()
}

struct GuestNodeView: View {
    let guest: GuestNode
    let isSelected: Bool
    let isDragging: Bool
    let geometry: GeometryProxy
    let onTap: () -> Void
    let onDrag: (Bool) -> Void
    
    @State private var isAnimating = false
    
    var nodeSize: CGFloat {
        30 + CGFloat(guest.partySize * 5)
    }
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [guest.group.color.opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: nodeSize / 2
                    )
                )
                .frame(width: nodeSize * 2, height: nodeSize * 2)
                .blur(radius: 10)
                .opacity(isAnimating ? 1 : 0.5)
            
            // Main node
            Circle()
                .fill(guest.group.color)
                .frame(width: nodeSize, height: nodeSize)
                .overlay(
                    Text("\(guest.partySize)")
                        .font(.system(size: nodeSize * 0.4, weight: .bold))
                        .foregroundColor(.white)
                )
                .overlay(
                    // Status indicator
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .overlay(
                            Circle()
                                .fill(Color(hex: guest.status.color))
                        )
                        .frame(width: 16, height: 16)
                        .offset(x: nodeSize / 2 - 8, y: -nodeSize / 2 + 8)
                )
            
            // Selection ring
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: nodeSize + 10, height: nodeSize + 10)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
            }
        }
        .scaleEffect(isDragging ? 1.2 : 1.0)
        .animation(.spring(response: 0.4), value: isDragging)
        .animation(.easeInOut(duration: 2).repeatForever(), value: isAnimating)
        .onAppear { isAnimating = true }
        .onTapGesture(perform: onTap)
        .gesture(
            DragGesture()
                .onChanged { _ in onDrag(true) }
                .onEnded { _ in onDrag(false) }
        )
    }
}

struct ConstellationConnections: View {
    let guests: [GuestNode]
    let animate: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        Canvas { context, size in
            for guest in guests {
                let guestPos = guestPosition(for: guest, in: geometry)
                
                for connectionId in guest.connections {
                    if let connectedGuest = guests.first(where: { $0.id == connectionId }) {
                        let connectedPos = guestPosition(for: connectedGuest, in: geometry)
                        
                        var path = Path()
                        path.move(to: guestPos)
                        path.addLine(to: connectedPos)
                        
                        context.stroke(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [guest.group.color, connectedGuest.group.color]),
                                startPoint: guestPos,
                                endPoint: connectedPos
                            ),
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round,
                                dash: animate ? [] : [5, 5]
                            )
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    func guestPosition(for guest: GuestNode, in geometry: GeometryProxy) -> CGPoint {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        let groupAngle = guest.group.angle
        let radius = guest.group.radius * min(geometry.size.width, geometry.size.height)
        
        let angle = groupAngle + (Double(guest.index) * 0.3)
        let x = centerX + cos(angle) * radius
        let y = centerY + sin(angle) * radius
        
        return CGPoint(x: x, y: y)
    }
}

struct StarfieldBackground: View {
    @State private var stars: [Star] = []
    
    struct Star {
        let id = UUID()
        let position: CGPoint
        let size: CGFloat
        let opacity: Double
        let animationDelay: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars, id: \.id) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .opacity(star.opacity)
                        .position(star.position)
                        .animation(
                            .easeInOut(duration: 3)
                                .repeatForever()
                                .delay(star.animationDelay),
                            value: star.opacity
                        )
                }
            }
            .onAppear {
                generateStars(in: geometry)
            }
        }
    }
    
    func generateStars(in geometry: GeometryProxy) {
        stars = (0..<100).map { _ in
            Star(
                position: CGPoint(
                    x: .random(in: 0...geometry.size.width),
                    y: .random(in: 0...geometry.size.height)
                ),
                size: .random(in: 1...3),
                opacity: .random(in: 0.1...0.6),
                animationDelay: .random(in: 0...3)
            )
        }
    }
}

struct GuestDetailCard: View {
    let guest: GuestNode
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(guest.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label("\(guest.partySize) guest\(guest.partySize > 1 ? "s" : "")", 
                              systemImage: "person.fill")
                        
                        Spacer()
                        
                        RSVPStatusBadge(status: guest.status)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 20) {
                DetailButton(icon: "envelope", title: "Message")
                DetailButton(icon: "chair", title: "Assign Table")
                DetailButton(icon: "pencil", title: "Edit")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

struct DetailButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
        )
    }
}

struct GroupFilterBar: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                GroupFilterChip(title: "All", isSelected: true)
                GroupFilterChip(title: "Family", isSelected: false)
                GroupFilterChip(title: "Friends", isSelected: false)
                GroupFilterChip(title: "Pending", isSelected: false)
            }
        }
    }
}

struct GroupFilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.pink : Color.gray.opacity(0.2))
            )
    }
}

struct AddGuestButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .font(.title)
                .foregroundColor(.pink)
        }
    }
}

struct RSVPStatusBadge: View {
    let status: RSVPStatus
    
    var body: some View {
        Text(status.text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: status.color))
            )
    }
}

struct GuestConstellationView_Previews: PreviewProvider {
    static var previews: some View {
        GuestConstellationView()
            .background(Color.black)
    }
}