import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Reference Object

enum ReferenceObject: String, CaseIterable, Identifiable {
    case boot       = "Boot (30cm)"
    case hand       = "Hand (20cm)"
    case metreSt    = "Metre stick (100cm)"
    case a4Paper    = "A4 paper (30cm)"
    case backpack   = "Backpack (50cm)"
    case custom     = "Custom..."

    var id: String { rawValue }

    /// Real-world size in metres (longest dimension used as reference).
    var realSizeMetres: Double {
        switch self {
        case .boot:    return 0.30
        case .hand:    return 0.20
        case .metreSt: return 1.00
        case .a4Paper: return 0.30
        case .backpack: return 0.50
        case .custom:  return 0.30   // placeholder; overridden by customSizeMetres
        }
    }
}

// MARK: - Size Estimation Overlay

/// Full-screen overlay that lets the ranger draw a rectangle over the
/// captured photo and pick a reference object for scale. It then calculates
/// an estimated infestation area and returns it via `estimatedArea`.
struct SizeEstimationOverlay: View {

    // MARK: Bindings / environment

    let image: UIImage
    @Binding var estimatedArea: String?
    @Environment(\.dismiss) private var dismiss

    // MARK: Rectangle state (in unit space 0…1 relative to displayed image)

    @State private var rectOrigin: CGPoint  = CGPoint(x: 0.25, y: 0.25)
    @State private var rectSize:   CGSize   = CGSize(width: 0.50, height: 0.50)

    // Corner drag state — stores the offset added during an active drag
    @State private var dragCorner: Corner? = nil
    @State private var activeDragDelta: CGSize = .zero

    // MARK: Reference object

    @State private var selectedRef: ReferenceObject = .boot
    @State private var customSizeText: String = "30"
    @State private var showCustomEntry = false

    // MARK: Helpers

    /// Effective real-world size in metres for the selected reference object.
    private var refSizeMetres: Double {
        if selectedRef == .custom,
           let v = Double(customSizeText), v > 0 {
            return v / 100.0   // user enters cm
        }
        return selectedRef.realSizeMetres
    }

    /// Computed area estimate based on current rect and a "reference pixel"
    /// assumption (the reference object fills the short edge of the rect).
    /// Formula: (rectArea_px / refObj_px²) × refObj_real_m²
    /// We assume the reference object spans the *shorter* side of the rect.
    private func computeArea(in displaySize: CGSize) -> Double {
        let imgRect = imageDrawRect(in: displaySize)
        guard imgRect.width > 0, imgRect.height > 0 else { return 0 }

        // Convert unit-space rect to pixel dimensions within the drawn image
        let rectWidthPx  = rectSize.width  * imgRect.width
        let rectHeightPx = rectSize.height * imgRect.height

        let rectAreaPx   = rectWidthPx * rectHeightPx
        let refPx        = min(rectWidthPx, rectHeightPx)   // shorter side = reference

        guard refPx > 0 else { return 0 }

        let refReal = refSizeMetres
        let scale   = refReal / refPx                        // metres per pixel
        let area    = rectAreaPx * scale * scale             // m²
        return area
    }

    private func formattedArea(_ area: Double) -> String {
        if area < 0.01 {
            return String(format: "~%.4f m²", area)
        } else if area < 10 {
            return String(format: "~%.1f m²", area)
        } else {
            return String(format: "~%.0f m²", area)
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ─────────────────────────────────────────────────
                headerBar

                // ── Photo + overlay ────────────────────────────────────────
                GeometryReader { geo in
                    let displaySize = geo.size
                    let imgRect = imageDrawRect(in: displaySize)

                    ZStack(alignment: .topLeading) {
                        // Photo
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Rectangle overlay
                        overlayRect(imgRect: imgRect, displaySize: displaySize)
                            .allowsHitTesting(true)

                        // Area badge
                        areaBadge
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                // ── Bottom controls ────────────────────────────────────────
                bottomControls
            }
        }
        .sheet(isPresented: $showCustomEntry) {
            customSizeSheet
        }
    }

    // MARK: - Sub-views

    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Skip")
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInkMuted)
                    .padding(.horizontal, DSSpace.md)
                    .padding(.vertical, DSSpace.sm)
            }

            Spacer()

            Text("Estimate Area")
                .font(DSFont.headline)
                .foregroundStyle(.white)

            Spacer()

            // Placeholder to balance Skip button width
            Text("Skip")
                .font(DSFont.callout)
                .foregroundStyle(.clear)
                .padding(.horizontal, DSSpace.md)
                .padding(.vertical, DSSpace.sm)
        }
        .padding(.horizontal, DSSpace.md)
        .padding(.top, DSSpace.sm)
        .background(Color.black)
    }

    private func overlayRect(imgRect: CGRect, displaySize: CGSize) -> some View {
        // Current unit-space origin + active drag delta (clamped later during commit)
        let clampedOrigin = rectOrigin
        let clampedSize   = rectSize

        let x = imgRect.minX + clampedOrigin.x * imgRect.width
        let y = imgRect.minY + clampedOrigin.y * imgRect.height
        let w = clampedSize.width  * imgRect.width
        let h = clampedSize.height * imgRect.height

        return ZStack(alignment: .topLeading) {
            // Semi-transparent fill
            Rectangle()
                .fill(Color.dsPrimary.opacity(0.20))
                .frame(width: w, height: h)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.dsPrimary, lineWidth: 2)
                )
                .offset(x: x, y: y)
                // Body drag — move the whole rect
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { val in
                            let dx = val.translation.width  / imgRect.width
                            let dy = val.translation.height / imgRect.height
                            let newX = (rectOrigin.x + dx).clamped(to: 0...(1 - rectSize.width))
                            let newY = (rectOrigin.y + dy).clamped(to: 0...(1 - rectSize.height))
                            rectOrigin = CGPoint(x: newX, y: newY)
                        }
                )

            // Corner handles
            ForEach(Corner.allCases, id: \.self) { corner in
                cornerHandle(corner: corner, x: x, y: y, w: w, h: h, imgRect: imgRect)
            }
        }
        .frame(width: displaySize.width, height: displaySize.height, alignment: .topLeading)
    }

    private func cornerHandle(
        corner: Corner, x: CGFloat, y: CGFloat,
        w: CGFloat, h: CGFloat, imgRect: CGRect
    ) -> some View {
        let hx: CGFloat
        let hy: CGFloat
        switch corner {
        case .topLeft:     hx = x;     hy = y
        case .topRight:    hx = x + w; hy = y
        case .bottomLeft:  hx = x;     hy = y + h
        case .bottomRight: hx = x + w; hy = y + h
        }

        let handleSize: CGFloat = 22

        return Circle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
            .overlay(Circle().strokeBorder(Color.dsPrimary, lineWidth: 2))
            .offset(
                x: hx - handleSize / 2,
                y: hy - handleSize / 2
            )
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { val in
                        applyCornerDrag(corner: corner, translation: val.translation, imgRect: imgRect)
                    }
            )
    }

    private var areaBadge: some View {
        // Needs display size — embed in GeometryReader indirectly; use preference key
        GeometryReader { geo in
            let area = computeArea(in: geo.size)
            let text = formattedArea(area)
            Text(text)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, DSSpace.md)
                .padding(.vertical, DSSpace.sm)
                .background(Color.dsPrimary.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, DSSpace.md)
                .allowsHitTesting(false)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: DSSpace.md) {
            // Reference object picker label
            Text("Reference object in photo:")
                .font(DSFont.callout)
                .foregroundStyle(Color.dsInk3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DSSpace.lg)

            // Horizontal scroll of chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpace.sm) {
                    ForEach(ReferenceObject.allCases) { ref in
                        Button {
                            selectedRef = ref
                            if ref == .custom { showCustomEntry = true }
                        } label: {
                            Text(ref == .custom && selectedRef == .custom
                                 ? "Custom (\(customSizeText) cm)"
                                 : ref.rawValue)
                                .font(DSFont.caption)
                                .foregroundStyle(selectedRef == ref ? .white : Color.dsInk2)
                                .padding(.horizontal, DSSpace.md)
                                .padding(.vertical, DSSpace.sm)
                                .background(
                                    selectedRef == ref
                                    ? Color.dsPrimary
                                    : Color.dsSurface
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            selectedRef == ref
                                            ? Color.dsPrimary
                                            : Color.dsDivider,
                                            lineWidth: 0.75
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DSSpace.lg)
            }

            // Instruction hint
            Text("Drag the green box to cover the infestation. Corner handles resize it.")
                .font(DSFont.caption)
                .foregroundStyle(Color.dsInk3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpace.lg)

            // Confirm button
            GeometryReader { geo in
                let area = computeArea(in: CGSize(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.width   // square approx; refined in overlay
                ))
                // We need to recompute with actual photo display size — use a preference key workaround.
                // For the confirm action we capture the area from the area badge instead.
                LargeButton(
                    title: "Confirm Estimate",
                    action: { confirmEstimate() },
                    isEnabled: true,
                    isLoading: false
                )
                .frame(width: geo.size.width)
            }
            .frame(height: 52)
            .padding(.horizontal, DSSpace.lg)
        }
        .padding(.vertical, DSSpace.md)
        .background(Color.dsBackground)
    }

    private var customSizeSheet: some View {
        NavigationStack {
            VStack(spacing: DSSpace.lg) {
                Text("Enter the real-world size of your reference object.")
                    .font(DSFont.callout)
                    .foregroundStyle(Color.dsInk2)
                    .multilineTextAlignment(.center)

                HStack {
                    TextField("e.g. 45", text: $customSizeText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                        .padding(DSSpace.md)
                        .background(Color.dsSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm))

                    Text("cm")
                        .font(DSFont.headline)
                        .foregroundStyle(Color.dsInk2)
                }

                LargeButton(
                    title: "Apply",
                    action: { showCustomEntry = false },
                    isEnabled: Double(customSizeText) != nil && Double(customSizeText)! > 0,
                    isLoading: false
                )
                .padding(.horizontal, DSSpace.lg)

                Spacer()
            }
            .padding(.top, DSSpace.xl)
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("Custom Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedRef = .boot      // revert to default
                        showCustomEntry = false
                    }
                    .foregroundStyle(Color.dsInk2)
                }
            }
        }
    }

    // MARK: - Actions

    private func confirmEstimate() {
        // Compute with screen width heuristic; the displayed photo height depends on
        // aspect ratio. Use screen dimensions as a good proxy.
        let screenW = UIScreen.main.bounds.width
        // Photo fills maxWidth; height is screenW / imageAspect
        let aspect  = image.size.width > 0 ? image.size.width / image.size.height : 1.0
        let displayH = screenW / aspect
        let area = computeArea(in: CGSize(width: screenW, height: displayH))
        estimatedArea = formattedArea(area)
        dismiss()
    }

    // MARK: - Geometry helpers

    /// The CGRect (in local coordinates of the GeometryReader) where the image
    /// is actually drawn when using `.scaledToFit()`.
    private func imageDrawRect(in containerSize: CGSize) -> CGRect {
        guard containerSize.width > 0, containerSize.height > 0,
              image.size.width > 0, image.size.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let imgAspect = image.size.width / image.size.height
        let boxAspect = containerSize.width / containerSize.height

        let drawSize: CGSize
        if imgAspect > boxAspect {
            // image is wider than box — letterboxed top/bottom
            drawSize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imgAspect
            )
        } else {
            // image is taller than box — pillarboxed left/right
            drawSize = CGSize(
                width: containerSize.height * imgAspect,
                height: containerSize.height
            )
        }
        let origin = CGPoint(
            x: (containerSize.width  - drawSize.width)  / 2,
            y: (containerSize.height - drawSize.height) / 2
        )
        return CGRect(origin: origin, size: drawSize)
    }

    /// Apply a corner drag by updating rectOrigin and rectSize in unit space.
    private func applyCornerDrag(corner: Corner, translation: CGSize, imgRect: CGRect) {
        guard imgRect.width > 0, imgRect.height > 0 else { return }

        let dx = translation.width  / imgRect.width
        let dy = translation.height / imgRect.height
        let minFraction: CGFloat = 0.05

        switch corner {
        case .topLeft:
            let newX = (rectOrigin.x + dx).clamped(to: 0...(rectOrigin.x + rectSize.width  - minFraction))
            let newY = (rectOrigin.y + dy).clamped(to: 0...(rectOrigin.y + rectSize.height - minFraction))
            let newW = rectSize.width  + (rectOrigin.x - newX)
            let newH = rectSize.height + (rectOrigin.y - newY)
            rectOrigin = CGPoint(x: newX, y: newY)
            rectSize   = CGSize(width: max(newW, minFraction), height: max(newH, minFraction))

        case .topRight:
            let newY = (rectOrigin.y + dy).clamped(to: 0...(rectOrigin.y + rectSize.height - minFraction))
            let newW = (rectSize.width + dx).clamped(to: minFraction...(1 - rectOrigin.x))
            let newH = rectSize.height + (rectOrigin.y - newY)
            rectOrigin = CGPoint(x: rectOrigin.x, y: newY)
            rectSize   = CGSize(width: newW, height: max(newH, minFraction))

        case .bottomLeft:
            let newX = (rectOrigin.x + dx).clamped(to: 0...(rectOrigin.x + rectSize.width  - minFraction))
            let newW = rectSize.width  + (rectOrigin.x - newX)
            let newH = (rectSize.height + dy).clamped(to: minFraction...(1 - rectOrigin.y))
            rectOrigin = CGPoint(x: newX, y: rectOrigin.y)
            rectSize   = CGSize(width: max(newW, minFraction), height: newH)

        case .bottomRight:
            let newW = (rectSize.width  + dx).clamped(to: minFraction...(1 - rectOrigin.x))
            let newH = (rectSize.height + dy).clamped(to: minFraction...(1 - rectOrigin.y))
            rectSize = CGSize(width: newW, height: newH)
        }
    }
}

// MARK: - Corner enum

enum Corner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}

// MARK: - Comparable clamping helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
