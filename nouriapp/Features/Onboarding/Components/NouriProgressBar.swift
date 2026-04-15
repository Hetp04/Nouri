//
//  NouriProgressBar.swift
//  nouriapp
//
//  Continuous progress bar — pass progress as 0.0 → 1.0
//

import SwiftUI

struct NouriProgressBar: View {
    /// 0.0 = empty, 1.0 = full
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(NouriColors.progressLine)
                    .frame(height: 4)

                // Fill
                Capsule()
                    .fill(NouriColors.brandGreen)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.35), value: progress)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    VStack(spacing: 24) {
        NouriProgressBar(progress: 0.2)
        NouriProgressBar(progress: 0.5)
        NouriProgressBar(progress: 1.0)
    }
    .padding()
}
