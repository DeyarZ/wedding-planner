import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// Pastel color palette
struct PastelColors {
    static let rose = Color(hex: "FFE4E1")      // Misty Rose
    static let lavender = Color(hex: "E6E6FA")  // Lavender
    static let peach = Color(hex: "FFDAB9")     // Peach Puff
    static let mint = Color(hex: "F0FFF0")      // Honeydew
    static let sky = Color(hex: "F0F8FF")       // Alice Blue
    static let cream = Color(hex: "FFFDD0")     // Cream
    static let blush = Color(hex: "FFC0CB")     // Pink
    static let sage = Color(hex: "D3E4D3")      // Sage
    static let pearl = Color(hex: "FDF5E6")     // Old Lace
    static let mauve = Color(hex: "E0B0FF")     // Mauve
}