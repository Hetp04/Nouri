//
//  CalorieCalculatorView.swift
//  nouriapp
//
//  Bottom sheet for estimating daily calorie needs.
//

import SwiftUI


// MARK: - CalorieCalculatorView

struct CalorieCalculatorView: View {
    @Environment(\.dismiss) var dismiss
    
    var onCalculate: ((Int) -> Void)? = nil

    // Source of truth — always metric. Rulers bind directly to these.
    @State private var weightKg: Double     = 115
    @State private var heightCm: Double     = 168
    @State private var weightUnit: WeightUnit = .kg
    @State private var heightUnit: HeightUnit = .cm
    @State private var activity: ActivityLevel = .lightlyActive
    @State private var age: Int = 25
    @State private var sex: Sex = .male
    
    private var targetCalories: Int {
        CalorieCalculator.maintenanceCalories(weightKg: weightKg, heightCm: heightCm, age: age, sex: sex, activity: activity)
    }

    // Displayed values as Doubles — converted from metric source of truth
    private var displayedWeight: Double {
        weightUnit == .pound ? UnitConvert.kgToLb(weightKg) : weightKg
    }
    private var displayedHeight: Double {
        heightUnit == .ft ? UnitConvert.cmToFt(heightCm) : heightCm
    }

    // Formatted strings for UI — always one decimal
    private var weightDisplayText: String { RulerMath.fmt(displayedWeight) }
    private var heightDisplayText: String { RulerMath.fmt(displayedHeight) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header ──────────────────────────────────────────────
                CalculatorHeader(dismiss: { dismiss() })

                Divider()

                // ── Profile ─────────────────────────────────────────────
                ProfileSection(age: $age, sex: $sex)

                Divider()

                // ── Weight ──────────────────────────────────────────────
                WeightSection(
                    weightKg: $weightKg,
                    unit: $weightUnit,
                    displayText: weightDisplayText
                )

                Divider()

                // ── Height ──────────────────────────────────────────────
                HeightSection(
                    heightCm: $heightCm,
                    unit: $heightUnit,
                    displayText: heightDisplayText
                )

                Divider()

                // ── Activity Level ──────────────────────────────────────
                ActivitySection(activity: $activity)



                // ── Calculate Button ────────────────────────────────────
                Button {
                    onCalculate?(targetCalories)
                    dismiss()
                } label: {
                    Text("Use \(targetCalories) kcal")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}



// MARK: - Subviews

private struct CalculatorHeader: View {
    let dismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Calculate for me")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(NouriColors.title)
                Text("We'll estimate your daily calories")
                    .font(.system(size: 15))
                    .foregroundStyle(NouriColors.subtitle)
            }
            
            Spacer()
            
            Button(action: dismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.gray.opacity(0.18))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 24)
    }
}

private struct ActivitySection: View {
    @Binding var activity: ActivityLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Activity level")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(NouriColors.subtitle)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    ActivityRow(level: level, selected: activity == level) {
                        withAnimation(.easeInOut(duration: 0.15)) { activity = level }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
    }
}

private struct ValueReadout: View {
    let text: String
    let unit: String
    let valueFont: CGFloat
    let unitFont: CGFloat
    let valueColor: Color
    let unitColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(text)
                .font(.system(size: valueFont, weight: .bold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(unit)
                .font(.system(size: unitFont, weight: .medium))
                .foregroundStyle(unitColor)
        }
    }
}

private struct ProfileSection: View {
    @Binding var age: Int
    @Binding var sex: Sex
    
    var body: some View {
        HStack(alignment: .center, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Age")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(NouriColors.subtitle)
                
                HStack(spacing: 8) {
                    Text("\(age)")
                        .font(.system(size: 20, weight: .semibold))
                        .monospacedDigit()
                    Stepper("", value: $age, in: 10...120)
                        .labelsHidden()
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Biological Sex")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(NouriColors.subtitle)
                
                ZStack {
                    Capsule()
                        .fill(Color(white: 0.93))
                        .frame(height: 32)
                    
                    GeometryReader { geo in
                        let w = geo.size.width / 2
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                            .padding(2)
                            .frame(width: w)
                            .offset(x: sex == .male ? 0 : w)
                    }
                    
                    HStack(spacing: 0) {
                        ForEach(Sex.allCases, id: \.self) { s in
                            Text(s.rawValue)
                                .font(.system(size: 13, weight: sex == s ? .semibold : .medium))
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                                        sex = s
                                    }
                                }
                        }
                    }
                }
                .frame(width: 140)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

/// Ruler always scrolls in kg. Display text converts to lb when needed.
private struct WeightSection: View {
    @Binding var weightKg: Double
    @Binding var unit: WeightUnit
    let displayText: String

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Weight", options: WeightUnit.allCases.map(\.rawValue), selected: unit.rawValue) { raw in
                unit = WeightUnit(rawValue: raw) ?? .kg
            }

            VStack(spacing: -2) {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(NouriColors.brandGreen)
                    .zIndex(1)

                ValueReadout(
                    text: displayText,
                    unit: unit == .kg ? "kg" : "lb",
                    valueFont: 40,
                    unitFont: 14,
                    valueColor: .white,
                    unitColor: .white.opacity(0.6)
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.vertical, 16)

            // Ruler always operates in kg (0–400 range)
            ArcRulerView(value: $weightKg, minValue: 0, maxValue: 400, showPounds: unit == .pound)
                .frame(height: 220)
                .padding(.bottom, 16)
        }
    }
}

/// Ruler always scrolls in cm. Display text converts to ft when needed.
private struct HeightSection: View {
    @Binding var heightCm: Double
    @Binding var unit: HeightUnit
    let displayText: String

    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Height", options: HeightUnit.allCases.map(\.rawValue), selected: unit.rawValue) { raw in
                unit = HeightUnit(rawValue: raw) ?? .cm
            }

            ValueReadout(
                text: displayText,
                unit: unit == .cm ? "cm" : "ft",
                valueFont: 56,
                unitFont: 18,
                valueColor: NouriColors.title,
                unitColor: NouriColors.subtitle
            )

            // Ruler always operates in cm (0–230 range)
            HorizontalRulerView(value: $heightCm, minValue: 0, maxValue: 230, showFeet: unit == .ft)
                .frame(height: 80)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }
}

// MARK: - Section Header & Toggle

private struct SectionHeader: View {
    let title: String
    let options: [String]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(NouriColors.subtitle)
            Spacer()
            HStack(spacing: 0) {
                ForEach(options, id: \.self) { opt in
                    Text(opt)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(opt == selected ? .white : NouriColors.subtitle)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(opt == selected ? Color.black : Color.clear)
                        .clipShape(Capsule())
                        .onTapGesture { onSelect(opt) }
                        .animation(.easeInOut(duration: 0.15), value: selected)
                }
            }
            .background(Color.gray.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - Arc Ruler (Weight — speedometer style)

private struct ArcRulerView: View {
    @Binding var value: Double
    var minValue: Double
    var maxValue: Double
    var showPounds: Bool = false

    // ── Tuning Constants ──
    private let degsPerUnit: Double = 1.3   // arc spread per kg
    private let visibleDegs: Double = 95.0  // half-arc visible range
    private let dragSensitivity: Double = 0.08  // kg per pixel dragged

    @State private var lastDragX: CGFloat = 0
    @State private var ticker: Timer?

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let r: CGFloat  = size.width * 0.48
            let cy: CGFloat = r + 12

            ctx.translateBy(x: cx, y: cy)

            // Resolve unit-specific scale
            let unitScale: Double  // degs per displayed unit
            let centerVal: Double  // center value in displayed units
            let tickStep: Int      // skip count (1 = draw every unit)

            if showPounds {
                let lbPerKg = UnitConvert.kgToLb(1)
                unitScale = degsPerUnit / lbPerKg
                centerVal = value * lbPerKg
                tickStep = 2  // every 2 lb ≈ density of 1 kg
            } else {
                unitScale = degsPerUnit
                centerVal = value
                tickStep = 1
            }

            let startV = Int(floor(centerVal - visibleDegs / unitScale))
            let endV   = Int(ceil(centerVal + visibleDegs / unitScale))

            for v in startV...endV {
                if v % tickStep != 0 { continue }

                var localCtx = ctx
                let angle = Angle.degrees((Double(v) - centerVal) * unitScale - 90)
                localCtx.rotate(by: angle)

                let isMajor = v % 20 == 0
                let isHalf  = v % 10 == 0 && !isMajor
                let len: CGFloat = isMajor ? 36 : (isHalf ? 22 : 12)

                let p = Path(CGRect(x: r - len, y: -0.5, width: len, height: 1))
                localCtx.fill(p, with: .color(.black.opacity(isMajor ? 0.7 : 0.3)))

                if isMajor {
                    var textCtx = localCtx
                    textCtx.translateBy(x: r - len - 20, y: 0)
                    textCtx.rotate(by: .degrees(-((Double(v) - centerVal) * unitScale - 90)))
                    textCtx.draw(
                        Text("\(v)").font(.system(size: 13, weight: .medium)).foregroundStyle(Color.gray),
                        at: .zero
                    )
                }
            }

            // Green center indicator needle
            var needleCtx = ctx
            needleCtx.rotate(by: .degrees(-90))
            var indicator = Path()
            indicator.move(to: CGPoint(x: r, y: 0))
            indicator.addLine(to: CGPoint(x: r - 40, y: 0))
            needleCtx.stroke(indicator, with: .color(NouriColors.brandGreen), lineWidth: 3.5)

            let dotRect = CGRect(x: r - 43, y: -3, width: 6, height: 6)
            needleCtx.fill(Path(ellipseIn: dotRect), with: .color(NouriColors.brandGreen))
        }
        .mask(LinearGradient(colors: [.clear, .black, .black, .clear], startPoint: .leading, endPoint: .trailing))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { val in
                    ticker?.invalidate()
                    let delta = val.translation.width - lastDragX
                    lastDragX = val.translation.width
                    
                    let newValue = RulerMath.dragKg(
                        value,
                        deltaPixels: Double(delta),
                        sensitivity: dragSensitivity,
                        isPound: showPounds
                    )
                    value = max(minValue, min(maxValue, newValue))
                }
                .onEnded { val in
                    lastDragX = 0
                    snapToNearest(withVelocity: val.velocity.width)
                }
        )
    }

    private func snapToNearest(withVelocity velocity: CGFloat) {
        ticker?.invalidate()
        var currentVelocity = max(-RulerMath.maxFlingVelocity, min(velocity, RulerMath.maxFlingVelocity))

        ticker = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            guard abs(currentVelocity) > 20 else {
                timer.invalidate()
                withAnimation(.interpolatingSpring(stiffness: 140, damping: 16)) {
                    value = RulerMath.snapKgForDisplay(value, isPound: showPounds)
                }
                return
            }

            let delta = currentVelocity * (1.0/60.0)
            let newValue = RulerMath.dragKg(
                value,
                deltaPixels: Double(delta),
                sensitivity: dragSensitivity,
                isPound: showPounds
            )

            if newValue <= minValue || newValue >= maxValue {
                currentVelocity = 0
                value = max(minValue, min(maxValue, newValue))
            } else {
                value = newValue
            }
            currentVelocity *= RulerMath.frictionDecay
        }
    }
}

// MARK: - Horizontal Ruler (Height)

private struct HorizontalRulerView: View {
    @Binding var value: Double
    var minValue: Double
    var maxValue: Double
    var showFeet: Bool = false

    // ── Tuning Constants ──
    private let pxPerUnit: CGFloat = 10     // pixels per cm

    @State private var lastDragX: CGFloat = 0
    @State private var ticker: Timer?

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.03))
                .padding(.top, -4)

            Canvas { ctx, size in
                let cx = size.width / 2

                // Top spine
                var spine = Path()
                spine.move(to: CGPoint(x: 0, y: 0))
                spine.addLine(to: CGPoint(x: size.width, y: 0))
                ctx.stroke(spine, with: .color(Color.black.opacity(0.1)), lineWidth: 1)

                if showFeet {
                    let cmPerFt = UnitConvert.ftToCm(1)
                    let pxPerFt = pxPerUnit * cmPerFt
                    let ftValue = value / cmPerFt

                    let visibleFt = size.width / pxPerFt
                    let startV = Int(floor((ftValue - visibleFt / 2 - 1) * 10))
                    let endV   = Int(ceil((ftValue + visibleFt / 2 + 1) * 10))

                    for vDec in startV...endV {
                        let ft = Double(vDec) / 10.0
                        let x = cx + CGFloat(ft - ftValue) * pxPerFt
                        guard x >= 0 && x <= size.width else { continue }

                        let isMajor = vDec % 10 == 0
                        let isHalf  = vDec % 5 == 0 && !isMajor

                        drawTick(ctx: &ctx, x: x, isMajor: isMajor, isHalf: isHalf,
                                 label: isMajor ? String(format: "%.0f", ft) : nil)
                    }
                } else {
                    let visibleUnits = size.width / pxPerUnit
                    let startV = Int(max(minValue, value - visibleUnits / 2 - 2))
                    let endV   = Int(min(maxValue, value + visibleUnits / 2 + 2))

                    for v in startV...endV {
                        let x = cx + CGFloat(Double(v) - value) * pxPerUnit
                        guard x >= 0 && x <= size.width else { continue }

                        let isMajor = v % 10 == 0
                        let isHalf  = v % 5 == 0 && !isMajor

                        drawTick(ctx: &ctx, x: x, isMajor: isMajor, isHalf: isHalf,
                                 label: isMajor ? "\(v)" : nil)
                    }
                }
            }
            .mask(
                LinearGradient(
                    colors: [.clear, .black, .black, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            // ── Center Pointer Indicator ─────────────────────
            VStack(spacing: 0) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(NouriColors.brandGreen)
                    .offset(y: -4)

                Rectangle()
                    .fill(NouriColors.brandGreen)
                    .frame(width: 2.5, height: 42)
                    .cornerRadius(1.25)
                    .shadow(color: NouriColors.brandGreen.opacity(0.3), radius: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { val in
                    ticker?.invalidate()
                    let delta = val.translation.width - lastDragX
                    lastDragX = val.translation.width
                    
                    let newValue = RulerMath.dragCm(
                        value,
                        deltaPixels: Double(delta),
                        pxPerCm: Double(pxPerUnit),
                        isFeet: showFeet
                    )
                    value = max(minValue, min(maxValue, newValue))
                }
                .onEnded { val in
                    lastDragX = 0
                    snapToNearest(withVelocity: val.velocity.width)
                }
        )
    }

    /// Shared tick drawing — eliminates duplication between cm and ft branches
    private func drawTick(ctx: inout GraphicsContext, x: CGFloat,
                          isMajor: Bool, isHalf: Bool, label: String?) {
        let tickH: CGFloat = isMajor ? 32 : (isHalf ? 20 : 10)
        let alpha: Double  = isMajor ? 0.6 : (isHalf ? 0.35 : 0.15)
        let lw: CGFloat    = isMajor ? 1.5 : 1

        var p = Path()
        p.move(to: CGPoint(x: x, y: 0))
        p.addLine(to: CGPoint(x: x, y: tickH))
        ctx.stroke(p, with: .color(Color.black.opacity(alpha)), lineWidth: lw)

        if let label {
            ctx.draw(
                Text(label)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.6)),
                at: CGPoint(x: x, y: tickH + 10),
                anchor: .top
            )
        }
    }

    private func snapToNearest(withVelocity velocity: CGFloat) {
        ticker?.invalidate()
        var currentVelocity = max(-RulerMath.maxFlingVelocity, min(velocity, RulerMath.maxFlingVelocity))

        ticker = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            guard abs(currentVelocity) > 20 else {
                timer.invalidate()
                withAnimation(.interpolatingSpring(stiffness: 140, damping: 16)) {
                    value = RulerMath.snapCmForDisplay(value, isFeet: showFeet)
                }
                return
            }

            let delta = currentVelocity * (1.0 / 60.0)
            let newValue = RulerMath.dragCm(
                value,
                deltaPixels: Double(delta),
                pxPerCm: Double(pxPerUnit),
                isFeet: showFeet
            )

            if newValue <= minValue || newValue >= maxValue {
                currentVelocity = 0
                value = max(minValue, min(maxValue, newValue))
            } else {
                value = newValue
            }
            currentVelocity *= RulerMath.frictionDecay
        }
    }
}

// MARK: - Activity Level Row

private struct ActivityRow: View {
    let level: ActivityLevel
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Circular icon container
                ZStack {
                    Circle()
                        .fill(selected ? NouriColors.brandGreen : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: level.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selected ? .white : Color.gray.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NouriColors.title)
                    
                    Text(level.description)
                        .font(.system(size: 13))
                        .foregroundStyle(NouriColors.subtitle)
                }
                
                Spacer()
                
                // Selection checkmark
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(NouriColors.brandGreen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(selected ? NouriColors.brandGreen.opacity(0.04) : Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selected ? NouriColors.brandGreen : Color.gray.opacity(0.15),
                        lineWidth: selected ? 1.5 : 1
                    )
            }
            .shadow(color: Color.black.opacity(selected ? 0.05 : 0), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CalorieCalculatorView()
}
