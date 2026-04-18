import SwiftUI

// MARK: - Color tokens
extension Color {
    // Surfaces
    static let paper      = Color(hex: "F4EFE4")
    static let paperDeep  = Color(hex: "EAE1D0")
    static let card       = Color(hex: "FFFBF2")
    static let lineBase   = Color(hex: "3A3220")

    // Primary — deep eucalyptus
    static let euc        = Color(hex: "2E4634")
    static let eucDark    = Color(hex: "1E2F22")
    static let eucLight   = Color(hex: "4A6951")
    static let eucSoft    = Color(hex: "DCE3D8")

    // Accent — burnt ochre
    static let ochre      = Color(hex: "C26A2A")
    static let ochreDeep  = Color(hex: "9B4F1C")
    static let ochreSoft  = Color(hex: "F3DEC5")

    // Bark
    static let bark       = Color(hex: "5A4632")
    static let barkSoft   = Color(hex: "A89178")

    // Status
    static let statusActive      = Color(hex: "B8322A")
    static let statusActiveSoft  = Color(hex: "F2D7D3")
    static let statusTreat       = Color(hex: "C89231")
    static let statusTreatSoft   = Color(hex: "F5E2BE")
    static let statusCleared     = Color(hex: "4A7A4A")
    static let statusClearedSoft = Color(hex: "D6E4CF")

    // Ink (text)
    static let ink        = Color(hex: "1F1A10")
    static let ink2       = Color(hex: "3A3220")
    static let ink3       = Color(hex: "6B5F4A")
    static let inkMute    = Color(hex: "8F8471")

    // Hex initialiser
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: UInt64
        switch h.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
}

// MARK: - Card modifier
struct DSCard: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.card)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.lineBase.opacity(0.12), lineWidth: 1))
            .shadow(color: Color(hex: "281E0A").opacity(0.04), radius: 1, y: 1)
    }
}
extension View {
    func dsCard(padding: CGFloat = 16) -> some View { modifier(DSCard(padding: padding)) }
}

// MARK: - SyncBadge
enum SyncStatusKind { case synced, pending, conflict }

struct SyncBadge: View {
    let status: SyncStatusKind
    var body: some View {
        let (label, bg, fg, icon): (String, Color, Color, String) = {
            switch status {
            case .synced:   return ("synced",   .statusClearedSoft, .statusCleared, "checkmark")
            case .pending:  return ("pending",  .statusTreatSoft,   .statusTreat,   "clock")
            case .conflict: return ("conflict", .statusActiveSoft,  .statusActive,  "exclamationmark.triangle")
            }
        }()
        Label(label, systemImage: icon)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(fg)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(bg)
            .clipShape(Capsule())
    }
}
