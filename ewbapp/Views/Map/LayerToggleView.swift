import SwiftUI

struct LayerToggleView: View {
    @Binding var showSightings: Bool
    @Binding var showZones: Bool
    @Binding var showPatrols: Bool

    var body: some View {
        VStack(spacing: 0) {
            LayerIconButton(icon: "mappin.circle.fill", isOn: $showSightings, color: .red)
            Divider().frame(width: 28)
            LayerIconButton(icon: "square.dashed", isOn: $showZones, color: .orange)
            Divider().frame(width: 28)
            LayerIconButton(icon: "figure.walk", isOn: $showPatrols, color: .blue)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct LayerIconButton: View {
    let icon: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isOn ? color : Color(.systemGray3))
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }
}
