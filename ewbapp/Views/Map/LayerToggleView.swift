import SwiftUI

struct LayerToggleView: View {
    @Binding var showSightings: Bool
    @Binding var showZones: Bool
    @Binding var showPatrols: Bool

    var body: some View {
        HStack(spacing: 8) {
            LayerToggleChip(title: "Pins", icon: "mappin.circle.fill", isOn: $showSightings, color: .red)
            LayerToggleChip(title: "Zones", icon: "square.dashed", isOn: $showZones, color: .orange)
            LayerToggleChip(title: "Patrols", icon: "figure.walk", isOn: $showPatrols, color: .blue)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct LayerToggleChip: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isOn ? color : Color(.systemGray5))
            .foregroundColor(isOn ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
