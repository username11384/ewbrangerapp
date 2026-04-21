import SwiftUI

// MARK: - Design System
// Warm Australian bushland palette for Lama Lama Rangers — invasive plants control.
// All UI tokens live here. Never hardcode hex colors or magic spacing in views.

// MARK: - Color Tokens

extension Color {
    // Surfaces
    /// Warm parchment — main app background
    static let dsBackground   = Color(hex: "F7F3EC")
    /// Slightly deeper warm cream — secondary background, list rows
    static let dsSurface      = Color(hex: "EEE9DF")
    /// Card surfaces — close to white with warmth
    static let dsCard         = Color(hex: "FDFAF4")
    /// Hairline dividers
    static let dsDivider      = Color(hex: "D6CEBA")

    // Brand — deep rainforest green
    static let dsPrimary      = Color(hex: "2A5C3F")
    static let dsPrimaryDeep  = Color(hex: "1A3D28")
    static let dsPrimaryLight = Color(hex: "3D7A57")
    static let dsPrimarySoft  = Color(hex: "D4E6DA")

    // Accent — warm amber/ochre (field gear, CTA)
    static let dsAccent       = Color(hex: "C4692A")
    static let dsAccentDeep   = Color(hex: "9B4F1C")
    static let dsAccentSoft   = Color(hex: "F2DEC8")

    // Text
    static let dsInk          = Color(hex: "1C1309")   // near-black with warmth
    static let dsInk2         = Color(hex: "4A3A2A")   // secondary text
    static let dsInk3         = Color(hex: "7A6650")   // tertiary text
    static let dsInkMuted     = Color(hex: "A89880")   // placeholder / disabled

    // Status colors
    static let dsStatusActive    = Color(hex: "C94040")  // active infestation — alert red
    static let dsStatusActiveSoft = Color(hex: "FAE8E8")
    static let dsStatusTreat     = Color(hex: "C4692A")  // under treatment — amber
    static let dsStatusTreatSoft  = Color(hex: "F2DEC8")
    static let dsStatusCleared   = Color(hex: "2A7A4A")  // cleared — success green
    static let dsStatusClearedSoft = Color(hex: "DAEEE3")

    // Species colors — earthy, differentiated, legible on map
    static let dsSpeciesLantana          = Color(hex: "D4763A")  // burnt orange
    static let dsSpeciesRubberVine       = Color(hex: "7B5EA8")  // muted purple
    static let dsSpeciesPricklyAcacia    = Color(hex: "C4A32E")  // golden yellow
    static let dsSpeciesSicklepod        = Color(hex: "5E8C3A")  // olive green
    static let dsSpeciesRatsTailGrass    = Color(hex: "8B7355")  // warm brown
    static let dsSpeciesPondApple        = Color(hex: "2E7A6B")  // teal
    static let dsSpeciesUnknown          = Color(hex: "8E8E93")  // neutral gray

    // Sync
    static let dsSynced      = Color(hex: "2A7A4A")
    static let dsPending     = Color(hex: "C4692A")
    static let dsFailed      = Color(hex: "C94040")
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

enum DSFont {
    /// 28pt bold rounded — screen titles
    static let largeTitle  = Font.system(size: 28, weight: .bold,     design: .rounded)
    /// 22pt bold rounded — section headers, nav titles
    static let title       = Font.system(size: 22, weight: .bold,     design: .rounded)
    /// 18pt semibold — card titles, group headers
    static let headline    = Font.system(size: 18, weight: .semibold, design: .default)
    /// 16pt semibold — list row primaries, button labels
    static let subhead     = Font.system(size: 16, weight: .semibold, design: .default)
    /// 15pt regular — body copy
    static let body        = Font.system(size: 15, weight: .regular,  design: .default)
    /// 14pt medium — callouts, metadata
    static let callout     = Font.system(size: 14, weight: .medium,   design: .default)
    /// 13pt regular — secondary row detail
    static let footnote    = Font.system(size: 13, weight: .regular,  design: .default)
    /// 12pt regular — captions, timestamps
    static let caption     = Font.system(size: 12, weight: .regular,  design: .default)
    /// 11pt bold — badges, pills
    static let badge       = Font.system(size: 11, weight: .bold,     design: .default)
    /// Monospaced — GPS coords, timers
    static let mono        = Font.system(size: 13, weight: .medium,   design: .monospaced)
}

// MARK: - Spacing

enum DSSpace {
    static let xs: CGFloat   = 4
    static let sm: CGFloat   = 8
    static let md: CGFloat   = 12
    static let lg: CGFloat   = 16
    static let xl: CGFloat   = 24
    static let xxl: CGFloat  = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

enum DSRadius {
    static let xs: CGFloat   = 6
    static let sm: CGFloat   = 10
    static let md: CGFloat   = 14
    static let lg: CGFloat   = 18
    static let xl: CGFloat   = 24
    static let pill: CGFloat = 999
}

// MARK: - View Modifiers

struct DSCardModifier: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.dsCard)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                    .strokeBorder(Color.dsDivider.opacity(0.6), lineWidth: 0.75)
            )
            .shadow(color: Color.dsInk.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct DSElevatedCardModifier: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.dsCard)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                    .strokeBorder(Color.dsDivider.opacity(0.5), lineWidth: 0.75)
            )
            .shadow(color: Color.dsInk.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

extension View {
    /// Standard card surface: dsCard background, rounded corners, hairline border, subtle shadow
    func dsCard(padding: CGFloat = DSSpace.lg) -> some View {
        modifier(DSCardModifier(padding: padding))
    }

    /// Elevated card: stronger shadow for floating elements
    func dsElevatedCard(padding: CGFloat = DSSpace.lg) -> some View {
        modifier(DSElevatedCardModifier(padding: padding))
    }
}

// MARK: - Reusable Components

/// Pill-shaped status badge
struct DSStatusBadge: View {
    let label: String
    let color: Color
    let softColor: Color

    var body: some View {
        Text(label)
            .font(DSFont.badge)
            .foregroundStyle(color)
            .padding(.horizontal, DSSpace.sm)
            .padding(.vertical, 3)
            .background(softColor)
            .clipShape(Capsule())
    }
}

/// Zone / infestation status badge
struct DSZoneStatusBadge: View {
    let status: String

    var label: String {
        switch status {
        case "active":         return "Active"
        case "underTreatment": return "Treatment"
        case "cleared":        return "Cleared"
        default:               return status.capitalized
        }
    }

    var color: Color {
        switch status {
        case "active":         return .dsStatusActive
        case "underTreatment": return .dsStatusTreat
        case "cleared":        return .dsStatusCleared
        default:               return .dsInk3
        }
    }

    var softColor: Color {
        switch status {
        case "active":         return .dsStatusActiveSoft
        case "underTreatment": return .dsStatusTreatSoft
        case "cleared":        return .dsStatusClearedSoft
        default:               return .dsSurface
        }
    }

    var body: some View {
        DSStatusBadge(label: label, color: color, softColor: softColor)
    }
}

/// Sync status capsule badge
struct DSSyncBadge: View {
    let status: SyncStatus

    var body: some View {
        switch status {
        case .synced:
            DSStatusBadge(label: "Synced", color: .dsSynced, softColor: .dsStatusClearedSoft)
        case .pendingCreate, .pendingUpdate:
            DSStatusBadge(label: "Pending", color: .dsPending, softColor: .dsStatusTreatSoft)
        case .pendingDelete:
            DSStatusBadge(label: "Deleting", color: .dsFailed, softColor: .dsStatusActiveSoft)
        }
    }
}

/// Primary action button — full width, branded
struct DSPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpace.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(DSFont.subhead)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Color.dsPrimaryLight, Color.dsPrimary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .shadow(color: Color.dsPrimary.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

/// Secondary (outlined) button
struct DSSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpace.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(DSFont.subhead)
            }
            .foregroundStyle(Color.dsPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.dsPrimarySoft)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .strokeBorder(Color.dsPrimary.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Stat card for dashboard
struct DSStatCard: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                Spacer()
            }
            Text(value)
                .font(DSFont.title)
                .foregroundStyle(Color.dsInk)
            Text(title)
                .font(DSFont.caption)
                .foregroundStyle(Color.dsInk3)
        }
        .dsCard(padding: DSSpace.md)
    }
}

/// Section header used in scrolling views
struct DSSectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(DSFont.badge)
            .foregroundStyle(Color.dsInk3)
            .tracking(0.8)
            .padding(.horizontal, DSSpace.lg)
            .padding(.top, DSSpace.xl)
            .padding(.bottom, DSSpace.xs)
    }
}

/// Empty state placeholder
struct DSEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: DSSpace.md) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.dsInkMuted)
            Text(title)
                .font(DSFont.headline)
                .foregroundStyle(Color.dsInk2)
            Text(message)
                .font(DSFont.body)
                .foregroundStyle(Color.dsInk3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpace.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpace.xxxl)
    }
}
