//
//  CalorieGoalView.swift
//  nouriapp
//
//  Calorie daily-goal picker — design matched from calorie-ruler reference.
//

import SwiftUI

// MARK: - Constants
private let tickSpacing: CGFloat = 8   // pts per 5 kcal
private let tickValue: Int       = 5
private let maxCalories: Int       = 8500 // 1700 ticks × 5 kcal

// MARK: - CalorieGoalView
struct CalorieGoalView: View {
    var onBack: () -> Void
    var onNext: () -> Void

    // Live State
    @State private var calories: Int
    @State private var rulerOffset: CGFloat
    @State private var committedOffset: CGFloat

    // Snap & physics animation
    @State private var ticker: Timer?
    @FocusState private var isInputFocused: Bool
    @State private var showCalculatorSheet: Bool = false

    init(onBack: @escaping () -> Void = {}, onNext: @escaping () -> Void = {}) {
        self.onBack = onBack
        self.onNext = onNext
        
        // Dynamically compute the exact starting positions from the constants
        // This ensures the scale never misaligns if tickSpacing or tickValue are changed!
        let initialCal = 800
        _calories = State(initialValue: initialCal)
        
        let startingOffset = -(CGFloat(initialCal) / CGFloat(tickValue)) * tickSpacing
        _rulerOffset = State(initialValue: startingOffset)
        _committedOffset = State(initialValue: startingOffset)
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Main content ──────────────────────────────────────────────
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Image.bundled("calorie") 
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .padding(.bottom, 8)

                    Text("Daily calorie goal")
                        .font(.system(size: 28, weight: .semibold))
                        .tracking(-0.3)
                        .foregroundStyle(NouriColors.title)
                    
                    Text("Set your daily calorie target based on\nyour personal health and fitness goals.")
                        .font(.system(size: 15, weight: .regular))
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(NouriColors.subtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 0)

                Spacer()

                // Hero Number
                VStack(spacing: 6) {
                    TextField("0", value: $calories, format: .number)
                        .focused($isInputFocused)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 96, weight: .regular, design: .default))
                        .monospacedDigit()
                        .tracking(-2)
                        .foregroundStyle(NouriColors.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: calories)

                    Text("kcal / day")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.gray.opacity(0.8))
                }
                
                Spacer()

                // Ruler
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        let width = geo.size.width

                        ZStack(alignment: .top) {
                            Canvas { ctx, size in
                                drawRuler(in: ctx, size: size, offset: rulerOffset)
                            }
                            .frame(width: width, height: 140)
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .black, location: 0.25),
                                        .init(color: .black, location: 0.75),
                                        .init(color: .clear, location: 1)
                                    ],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )

                            // Glowing Brand Center Indicator
                            Rectangle()
                                .fill(NouriColors.brandGreen)
                                .frame(width: 3.5, height: 100)
                                .cornerRadius(1.75)
                                .shadow(color: NouriColors.brandGreen.opacity(0.4), radius: 6, x: 0, y: 0)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(height: 140)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { val in
                                ticker?.invalidate() // Catch it mid-spin
                                let raw = committedOffset + val.translation.width
                                let bounded = raw > 0 ? raw * 0.3 : raw
                                rulerOffset = bounded
                                updateCalories(from: bounded)
                            }
                            .onEnded { val in
                                committedOffset = rulerOffset
                                // Pass the flick velocity to physics method
                                snapToNearest(withVelocity: val.velocity.width)
                            }
                    )
                }
                .frame(height: 140)
                .padding(.bottom, 24)
                .overlay {
                    // Safe-Zone interceptor: When the keyboard is up, this invisible shield 
                    // covers the ruler. Any accidental swipe will just hit the shield, 
                    // dismissing the keyboard instead of violently spinning the scale.
                    if isInputFocused {
                        Color.white.opacity(0.001)
                            .contentShape(Rectangle())
                            .onTapGesture { isInputFocused = false }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in isInputFocused = false }
                            )
                    }
                }

                Button {
                    showCalculatorSheet = true
                } label: {
                    Text("I don't know my calories")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(NouriColors.subtitle)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sensoryFeedback(.selection, trigger: calories) 

            // ── Footer ────────────────────────────────────────────────────
            NouriOnboardingFooter(
                onBack: onBack,
                onNext: {
                    isInputFocused = false 
                    onNext()
                },
                nextButtonLabel: "Continue"
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .onChange(of: calories) { newValue in
            // Reverse-sync ruler physics seamlessly when typing 
            if isInputFocused {
                let boundedVal = max(0, min(newValue, maxCalories))
                let expectedOffset = -(CGFloat(boundedVal) / CGFloat(tickValue)) * tickSpacing
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    rulerOffset = expectedOffset
                    committedOffset = expectedOffset
                }
            }
        }
        .sheet(isPresented: $showCalculatorSheet) {
            CalorieCalculatorView { targetCal in
                calories = targetCal
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Ruler drawing (Canvas)
    private func drawRuler(in ctx: GraphicsContext, size: CGSize, offset: CGFloat) {
        let centerX = size.width / 2

        // Draw a subtle curved baseline
        // topPad ensures the tallest center ticks are never clipped at the Canvas top edge
        let topPad: CGFloat = 14
        var axisPath = Path()
        let steps = 20
        for i in 0...steps {
            let px = CGFloat(i) / CGFloat(steps) * size.width
            let dist = abs(px - centerX) / (size.width / 2)
            let py = topPad + dist * dist * 15
            if i == 0 { axisPath.move(to: CGPoint(x: px, y: py)) }
            else { axisPath.addLine(to: CGPoint(x: px, y: py)) }
        }
        ctx.stroke(axisPath, with: .color(Color.black.opacity(0.1)), lineWidth: 1.5)
        
        // OPTIMIZATION: Only loop through the ticks that are actively inside the screen bounds.
        // This drops the iterations per frame from exactly 1700 iterations down to ~50 iterations.
        let minX: CGFloat = -30
        let maxX: CGFloat = size.width + 30
        
        let startI = Int((minX - centerX - offset) / tickSpacing)
        let endI   = Int((maxX - centerX - offset) / tickSpacing)
        
        let safeStart = max(0, startI)
        let safeEnd   = min(maxCalories / tickValue, endI)
        
        guard safeStart <= safeEnd else { return }

        for i in safeStart...safeEnd {
            let cal = i * tickValue
            let x = centerX + offset + CGFloat(i) * tickSpacing

            let isMajor = cal % 100 == 0
            // Clean sequential evaluation of tick hierarchy (Height, Width, Opacity)
            // Proportional scaling for the larger 140pt frame
            let (tickH, tickW, opacity): (CGFloat, CGFloat, Double) = {
                if isMajor       { return (50, 2.0, 0.30) }
                if cal % 50 == 0 { return (36, 1.5, 0.20) }
                if cal % 10 == 0 { return (24, 1.5, 0.12) }
                return (14, 1.5, 0.05)
            }()

            // Curve: ticks rise from edges toward center, lifted by topPad
            let distNorm = abs(x - centerX) / (size.width / 2)
            let curveY = topPad + distNorm * distNorm * 15
            let scaleFade = 1.0 - (distNorm * 0.3)

            let rect = CGRect(x: x - tickW / 2, y: curveY, width: tickW, height: tickH)
            var path = Path()
            path.addRoundedRect(in: rect, cornerSize: .init(width: tickW/2, height: tickW/2))
            ctx.fill(path, with: .color(Color.black.opacity(opacity * scaleFade)))

            // Label for every 100 kcal (skip 0)
            if isMajor && cal > 0 {
                let label = "\(cal)"
                let textY = curveY + tickH + 12
                ctx.draw(
                    Text(label)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.gray.opacity(0.8 * scaleFade)),
                    at: CGPoint(x: x, y: textY),
                    anchor: .top
                )
            }
        }
    }

    // MARK: - Helpers
    private func updateCalories(from offset: CGFloat) {
        // Find exact discrete tick index 
        let tickIndex = Int(round(-offset / tickSpacing))
        let targetCalories = max(0, min(tickIndex * tickValue, maxCalories))
        
        // Bypass if user is actively entering via keyboard
        if targetCalories != calories && !isInputFocused {
            calories = targetCalories
        }
    }

    private func snapToNearest(withVelocity velocity: CGFloat = 0) {
        ticker?.invalidate()
        let maxV: CGFloat = 4000
        var currentVelocity = max(-maxV, min(velocity, maxV))
        
        // 60fps Coasting Timer
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            guard abs(currentVelocity) > 30 else {
                timer.invalidate()
                // Final precision settle
                let snapped = round(rulerOffset / tickSpacing) * tickSpacing
                let bounded = min(0, snapped)
                withAnimation(.interpolatingSpring(stiffness: 140, damping: 16)) {
                    rulerOffset = bounded
                    committedOffset = bounded
                    updateCalories(from: bounded)
                }
                return
            }
            
            // Advance offset continuously per frame
            let delta = currentVelocity * (1.0/60.0)
            var newOffset = rulerOffset + delta
            
            // Hard bounds at 0
            if newOffset > 0 {
                newOffset = 0
                currentVelocity = 0
            }
            
            // Update layout sequentially
            rulerOffset = newOffset
            committedOffset = newOffset
            updateCalories(from: newOffset)
            
            // Apply friction bleed
            currentVelocity *= 0.94
        }
    }
}

// MARK: - Preview
#Preview("Calorie Goal") {
    CalorieGoalView()
        .background(NouriColors.canvas.ignoresSafeArea())
}
