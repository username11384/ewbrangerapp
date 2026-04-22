import SwiftUI

struct RedLightModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content.colorMultiply(Color(red: 1, green: 0.15, blue: 0.15))
        } else {
            content
        }
    }
}
