//
//  ProcessLevelView.swift
//  nouriapp
//

import SwiftUI

// MARK: - Data



// MARK: - Vertical Slider Component

private struct FrequencySlider: View {
    @Binding var selectedValue: Int
    var animateHint: Bool = true

    private let handleSize: CGFloat = 56
    private let spacing: CGFloat = 48
    private let trackWidth: CGFloat = 8

    private var step: CGFloat { handleSize + spacing }

    private func yForValue(_ v: Int) -> CGFloat {
        CGFloat(TopicRegistry.frequencyLevels.count - 1 - v) * step
    }

    var currentLevel: FrequencyLevel { TopicRegistry.frequencyLevels[selectedValue] }

    @State private var baseY: CGFloat = 0
    @State private var handleY: CGFloat = 0
    @State private var isHinting: Bool = false
    @State private var hintDone: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Track & Handle Column
            ZStack(alignment: .top) {
                // 1. Full Track
                Capsule()
                    .fill(Color(red: 229/255, green: 229/255, blue: 229/255))
                    .frame(width: trackWidth)

                // 2. Active Track — position follows handleY, color follows selectedValue
                GeometryReader { geo in
                    let currentY = (isHinting ? handleY : yForValue(selectedValue)) + handleSize / 2
                    let bottomY = geo.size.height

                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: currentY)
                        Capsule()
                            .fill(currentLevel.accent)
                            .frame(height: max(0, bottomY - currentY))
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedValue)
                    }
                    .frame(width: trackWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                // 3. Handle — icon/color from selectedValue (always centered), position from handleY during hint
                ZStack {
                    Circle()
                        .fill(Color.white)
                    Circle()
                        .strokeBorder(currentLevel.accent, lineWidth: 3)
                    Image(systemName: currentLevel.icon)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(currentLevel.accent)
                        .contentTransition(.identity)
                }
                .frame(width: handleSize, height: handleSize)
                .shadow(color: currentLevel.accent.opacity(0.35), radius: 8, y: 4)
                // Instantly snap icon/color — no cross-fade trail
                .animation(.none, value: selectedValue)
                .offset(y: isHinting ? handleY : yForValue(selectedValue))
                .animation(isHinting ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: selectedValue)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            guard !isHinting else { return }
                            let rawY = baseY + gesture.translation.height
                            let rawIndex = rawY / step
                            let v = TopicRegistry.frequencyLevels.count - 1 - Int(round(rawIndex))
                            let clamped = min(max(v, 0), TopicRegistry.frequencyLevels.count - 1)
                            if clamped != selectedValue {
                                selectedValue = clamped
                            }
                        }
                        .onEnded { _ in
                            baseY = yForValue(selectedValue)
                        }
                )
            }
            .frame(width: handleSize)
            .onAppear {
                handleY = yForValue(selectedValue)
                baseY = yForValue(selectedValue)
                
                if selectedValue == 0 && animateHint && !hintDone {
                    hintDone = true
                    runHintAnimation()
                }
            }

            // Labels Column
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(TopicRegistry.frequencyLevels.indices.reversed(), id: \.self) { i in
                    let level = TopicRegistry.frequencyLevels[i]
                    let isActive = level.value == selectedValue
                    VStack(alignment: .leading, spacing: 3) {
                        Text(level.label)
                            .font(.system(size: 16, weight: isActive ? .bold : .regular))
                            .foregroundStyle(isActive ? Color(red: 32/255, green: 33/255, blue: 35/255) : Color(red: 161/255, green: 161/255, blue: 170/255))
                        Text(level.description)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 142/255, green: 142/255, blue: 147/255))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: handleSize, alignment: .center)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isHinting else { return }
                        selectedValue = level.value
                        baseY = yForValue(selectedValue)
                    }
                    .opacity(isActive ? 1 : (abs(level.value - selectedValue) == 1 ? 0.7 : 0.4))
                    .animation(.easeInOut(duration: 0.2), value: selectedValue)
                }
            }
        }
    }

    private func runHintAnimation() {
        Task { @MainActor in
            isHinting = true
            
            try? await Task.sleep(nanoseconds: 400_000_000)
            
            // ── Glide UP: Never → Often ──
            withAnimation(.easeInOut(duration: 0.55)) { handleY = yForValue(2) }
            try? await Task.sleep(nanoseconds: 176_000_000)
            selectedValue = 1
            try? await Task.sleep(nanoseconds: 198_000_000)
            selectedValue = 2
            
            // ── Brief pause ──
            try? await Task.sleep(nanoseconds: 356_000_000)
            
            // ── Glide BACK: Often → Never ──
            withAnimation(.easeInOut(duration: 0.55)) { handleY = yForValue(0) }
            try? await Task.sleep(nanoseconds: 176_000_000)
            selectedValue = 1
            try? await Task.sleep(nanoseconds: 198_000_000)
            selectedValue = 0
            
            // ── Clean up ──
            try? await Task.sleep(nanoseconds: 276_000_000)
            isHinting = false
            baseY = yForValue(selectedValue)
        }
    }
}

// MARK: - Screen

struct ProcessLevelView: View {
    var animateHint: Bool = true
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}

    @EnvironmentObject var onboardingData: OnboardingData

    var body: some View {
        NouriOnboardingWrapper(onBack: onBack, onNext: onNext) {
            VStack(alignment: .leading, spacing: 0) {
                NouriOnboardingHeader(
                    imageName: "ultra",
                    title: OnboardingCopy.ProcessLevel.title,
                    subtitle: OnboardingCopy.ProcessLevel.subtitle,
                    accessibilityLabel: OnboardingCopy.ProcessLevel.accessibilityLabel,
                    imageScale: 1.2
                )

                FrequencySlider(selectedValue: $onboardingData.processLevel, animateHint: animateHint)
                    .sensoryFeedback(.impact(weight: .light), trigger: onboardingData.processLevel)
                    .padding(.horizontal, 8)
            }
        }
    }
}

#Preview("Process Level") {
    ProcessLevelView()
        .environmentObject(OnboardingData.shared)
}
