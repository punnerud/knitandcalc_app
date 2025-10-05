import SwiftUI

struct RulerView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var selectedUnit: RulerUnit = .cm
    @State private var scrollOffset: CGPoint = .zero
    @State private var showResetButton: Bool = false
    @State private var showCalibration: Bool = false
    @State private var calibrationOffset: CGFloat = 0.0
    @AppStorage("rulerCalibrationCM") private var savedCalibrationCM: Double = -0.03
    @AppStorage("rulerCalibrationInch") private var savedCalibrationInch: Double = 0.06

    enum RulerUnit: String, CaseIterable {
        case cm = "CM"
        case inch = "IN"

        func pixelsPerUnit(devicePPI: Int?, calibration: CGFloat) -> CGFloat {
            let basePPI: CGFloat
            if let ppi = devicePPI {
                basePPI = CGFloat(ppi)
            } else {
                // Fallback if device not found
                basePPI = 163.0 // approximate default
            }

            // Convert physical pixels to points (UIKit uses points)
            let scale = UIScreen.main.scale
            let pointsPerInch = basePPI / scale
            let adjustedPointsPerInch = pointsPerInch * (1.0 + calibration)

            print("📏 Scale: \(scale)x, PPI: \(basePPI), Points/inch: \(pointsPerInch)")

            switch self {
            case .cm:
                return adjustedPointsPerInch / 2.54 // convert to points per cm
            case .inch:
                return adjustedPointsPerInch
            }
        }

        var smallDivisions: Int {
            switch self {
            case .cm: return 10
            case .inch: return 16
            }
        }

        var maxValue: Int {
            switch self {
            case .cm: return 100
            case .inch: return 39
            }
        }
    }

    var body: some View {
        let deviceInfo = DeviceInfo.current()
        let savedCalibration = selectedUnit == .cm ? savedCalibrationCM : savedCalibrationInch
        let calibration = CGFloat(savedCalibration) + calibrationOffset

        GeometryReader { geometry in
            ZStack {
                Color.appRulerBackground
                    .ignoresSafeArea()

                // Scrollable content area with offset tracking
                OffsetTrackingScrollView(offset: $scrollOffset) {
                    RulerContent(unit: selectedUnit, devicePPI: deviceInfo.ppi, calibration: calibration)
                }
                .onChange(of: scrollOffset) { newValue in
                    let pixelsPerUnit = selectedUnit.pixelsPerUnit(devicePPI: deviceInfo.ppi, calibration: calibration)
                    let threshold = pixelsPerUnit * 10
                    withAnimation {
                        showResetButton = abs(newValue.y) > threshold || abs(newValue.x) > threshold
                    }
                }

                // Fixed top horizontal ruler
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        // Corner
                        Rectangle()
                            .fill(Color.appRulerBackground)
                            .frame(width: 54, height: 54)

                        // Horizontal ruler marks
                        HorizontalRulerMarks(unit: selectedUnit, offset: scrollOffset.x, devicePPI: deviceInfo.ppi, calibration: calibration)
                    }
                    .frame(height: 54)
                    .allowsHitTesting(false)

                    Spacer()
                }

                // Fixed left vertical ruler
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        // Top space
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 64, height: 54)

                        // Vertical ruler marks
                        VerticalRulerMarks(unit: selectedUnit, offset: scrollOffset.y, devicePPI: deviceInfo.ppi, calibration: calibration)
                    }
                    .frame(width: 64)
                    .allowsHitTesting(false)

                    Spacer()
                }

                // Bottom controls
                VStack {
                    Spacer()

                    VStack(spacing: 12) {
                        if showResetButton {
                            Button(action: resetRuler) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Nullstill")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.appButtonBackground)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        HStack(spacing: 12) {
                            // Calibration button
                            Button(action: { showCalibration.toggle() }) {
                                Image(systemName: showCalibration ? "slider.horizontal.3" : "ruler")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(showCalibration ? .appButtonText : .appButtonTextUnselected)
                                    .frame(width: 50, height: 50)
                                    .background(showCalibration ?
                                        Color.appButtonBackground :
                                        Color.appButtonBackgroundUnselected)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                            }
                            ForEach(RulerUnit.allCases, id: \.self) { unit in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedUnit = unit
                                        calibrationOffset = 0.0
                                        // Update settings when unit changes
                                        settings.currentUnitSystem = unit == .inch ? .imperial : .metric
                                    }
                                }) {
                                    Text(unit.rawValue)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(selectedUnit == unit ? .appButtonText : .appButtonTextUnselected)
                                        .frame(width: 80, height: 50)
                                        .background(selectedUnit == unit ?
                                            Color.appButtonBackground :
                                            Color.appButtonBackgroundUnselected)
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)

                        // Calibration slider
                        if showCalibration {
                            VStack(spacing: 8) {
                                Text("Kalibrering")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.appSecondaryText)

                                HStack(spacing: 12) {
                                    Button(action: { adjustCalibration(-0.01) }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(Color.appButtonBackground)
                                            .cornerRadius(8)
                                    }

                                    Slider(value: $calibrationOffset, in: -0.2...0.2, step: 0.005)
                                        .accentColor(Color.appButtonBackground)

                                    Button(action: { adjustCalibration(0.01) }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(Color.appButtonBackground)
                                            .cornerRadius(8)
                                    }
                                }

                                HStack(spacing: 8) {
                                    Button(action: saveCalibration) {
                                        Text("Lagre")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.appButtonBackground)
                                            .cornerRadius(8)
                                    }

                                    Button(action: resetCalibration) {
                                        Text("Tilbakestill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.appSecondaryText)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.appButtonBackgroundUnselected)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.appSecondaryBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
        }
        .navigationTitle("Linjal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Set initial unit based on settings
            selectedUnit = settings.currentUnitSystem == .imperial ? .inch : .cm
        }
    }

    func adjustCalibration(_ delta: CGFloat) {
        calibrationOffset = min(max(calibrationOffset + delta, -0.2), 0.2)
    }

    func saveCalibration() {
        if selectedUnit == .cm {
            savedCalibrationCM += Double(calibrationOffset)
        } else {
            savedCalibrationInch += Double(calibrationOffset)
        }
        calibrationOffset = 0.0
        withAnimation {
            showCalibration = false
        }
    }

    func resetCalibration() {
        if selectedUnit == .cm {
            savedCalibrationCM = -0.03
        } else {
            savedCalibrationInch = 0.06
        }
        calibrationOffset = 0.0
    }

    func resetRuler() {
        NotificationCenter.default.post(name: .scrollToTop, object: nil)
    }
}

// Scrollable content
struct RulerContent: View {
    let unit: RulerView.RulerUnit
    let devicePPI: Int?
    let calibration: CGFloat

    var body: some View {
        let pixelsPerUnit = unit.pixelsPerUnit(devicePPI: devicePPI, calibration: calibration)
        let totalWidth = CGFloat(unit.maxValue) * pixelsPerUnit + 1000
        let totalHeight = CGFloat(unit.maxValue) * pixelsPerUnit + 1000

        Color.appRulerBackground
            .frame(width: totalWidth, height: totalHeight)
    }
}

// Offset tracking scroll view using UIScrollView
struct OffsetTrackingScrollView<Content: View>: UIViewRepresentable {
    @Binding var offset: CGPoint
    let content: Content

    init(offset: Binding<CGPoint>, @ViewBuilder content: () -> Content) {
        self._offset = offset
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(offset: $offset)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        scrollView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        context.coordinator.hostingController = hostingController
        context.coordinator.scrollView = scrollView

        // Listen for reset notification
        NotificationCenter.default.addObserver(
            forName: .scrollToTop,
            object: nil,
            queue: .main
        ) { _ in
            scrollView.setContentOffset(.zero, animated: true)
        }

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var offset: CGPoint
        var hostingController: UIHostingController<Content>?
        weak var scrollView: UIScrollView?

        init(offset: Binding<CGPoint>) {
            self._offset = offset
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Clamp scroll offset to prevent going beyond content
            var newOffset = scrollView.contentOffset
            let maxX = max(0, scrollView.contentSize.width - scrollView.bounds.width)
            let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)

            newOffset.x = max(0, min(newOffset.x, maxX))
            newOffset.y = max(0, min(newOffset.y, maxY))

            offset = newOffset
        }
    }
}

// Horizontal ruler marks (fixed at top)
struct HorizontalRulerMarks: View {
    let unit: RulerView.RulerUnit
    let offset: CGFloat
    let devicePPI: Int?
    let calibration: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let pixelsPerUnit = unit.pixelsPerUnit(devicePPI: devicePPI, calibration: calibration)
            let smallDivisions = unit.smallDivisions
            let width = geometry.size.width
            let startUnit = max(0, min(unit.maxValue, Int(floor(offset / pixelsPerUnit))))
            let endUnit = min(unit.maxValue, max(startUnit, Int(ceil((offset + width) / pixelsPerUnit)) + 1))

            ZStack(alignment: .topLeading) {
                Color.appRulerBackground

                HStack(spacing: 0) {
                    ForEach(startUnit...endUnit, id: \.self) { value in
                        HStack(spacing: 0) {
                            // 0.5mm offset before marker (cm only)
                            if unit == .cm {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: pixelsPerUnit / 20, height: 54)
                            }

                            // Main cm/inch marker
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color(white: 0.3))
                                    .frame(width: 2, height: 30)

                                if value > 0 {
                                    Text("\(value)")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(Color(white: 0.3))
                                        .frame(width: pixelsPerUnit, height: 24)
                                } else {
                                    Spacer()
                                        .frame(height: 24)
                                }
                            }
                            .frame(width: 2)

                            // 0.5mm offset after marker (cm only)
                            if unit == .cm {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: pixelsPerUnit / 20, height: 54)
                            }

                            // Small divisions (mm or 16ths)
                            if value < unit.maxValue {
                                HStack(spacing: 0) {
                                    ForEach(1..<smallDivisions, id: \.self) { division in
                                        let isMidpoint = (division == smallDivisions / 2)
                                        let lineHeight: CGFloat = isMidpoint ? 20 : 15
                                        let lineWidth: CGFloat = isMidpoint ? 1.5 : 1
                                        let divisionWidth = pixelsPerUnit / CGFloat(smallDivisions)

                                        VStack(spacing: 0) {
                                            Rectangle()
                                                .fill(Color(white: 0.5))
                                                .frame(width: lineWidth, height: lineHeight)

                                            Spacer()
                                        }
                                        .frame(width: divisionWidth, height: 54)
                                    }
                                }
                            }
                        }
                    }
                }
                .offset(x: -offset + CGFloat(startUnit) * pixelsPerUnit)
            }
        }
    }
}

// Vertical ruler marks (fixed on left)
struct VerticalRulerMarks: View {
    let unit: RulerView.RulerUnit
    let offset: CGFloat
    let devicePPI: Int?
    let calibration: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let pixelsPerUnit = unit.pixelsPerUnit(devicePPI: devicePPI, calibration: calibration)
            let smallDivisions = unit.smallDivisions
            let height = geometry.size.height
            let startUnit = max(0, min(unit.maxValue, Int(floor(offset / pixelsPerUnit))))
            let endUnit = min(unit.maxValue, max(startUnit, Int(ceil((offset + height) / pixelsPerUnit)) + 1))

            ZStack(alignment: .topLeading) {
                Color.appRulerBackground

                VStack(spacing: 0) {
                    ForEach(startUnit...endUnit, id: \.self) { value in
                        VStack(spacing: 0) {
                            // 0.5mm offset before marker (cm only)
                            if unit == .cm {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 64, height: pixelsPerUnit / 20)
                            }

                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color(white: 0.3))
                                    .frame(width: 30, height: 2)

                                if value > 0 {
                                    Text("\(value)")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(Color(white: 0.3))
                                        .rotationEffect(.degrees(90))
                                        .frame(width: 34, alignment: .leading)
                                        .padding(.leading, 4)
                                } else {
                                    Spacer()
                                        .frame(width: 34)
                                }
                            }
                            .frame(height: 2)

                            // 0.5mm offset after marker (cm only)
                            if unit == .cm {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 64, height: pixelsPerUnit / 20)
                            }

                            if value < unit.maxValue {
                                ForEach(1..<smallDivisions, id: \.self) { division in
                                    let isMidpoint = (division == smallDivisions / 2)
                                    let lineWidth: CGFloat = isMidpoint ? 20 : 15
                                    let lineHeight: CGFloat = isMidpoint ? 1.5 : 1
                                    let divisionHeight = pixelsPerUnit / CGFloat(smallDivisions)

                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color(white: 0.5))
                                            .frame(width: lineWidth, height: lineHeight)

                                        Spacer()
                                    }
                                    .frame(height: divisionHeight)
                                }
                            }
                        }
                    }
                }
                .offset(y: -offset + CGFloat(startUnit) * pixelsPerUnit)
            }
        }
    }
}

extension Notification.Name {
    static let scrollToTop = Notification.Name("scrollToTop")
}

#Preview {
    NavigationView {
        RulerView()
    }
}