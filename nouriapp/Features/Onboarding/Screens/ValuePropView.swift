import SwiftUI

struct ValuePropView: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            // TOP-ALIGNED MINIMAL CONTENT
            VStack(alignment: .center, spacing: 14) {
                // NEUTRAL BREADCRUMB TAG
                Text(OnboardingCopy.ValueProp.tag)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.4))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.black.opacity(0.04), in: Capsule())
                
                VStack(alignment: .center, spacing: 6) {
                    Text(OnboardingCopy.ValueProp.title)
                        .font(.system(size: 24, weight: .semibold))
                        .tracking(-0.3)
                        .foregroundStyle(NouriColors.title)
                        .multilineTextAlignment(.center)
                    
                    Text(OnboardingCopy.ValueProp.subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .lineSpacing(4)
                        .foregroundStyle(Color.black.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8).padding(.bottom, 24)
            .padding(.horizontal, 30)
            
            Spacer()
            
            // FOOTER
            NouriOnboardingFooter(onBack: onBack, onNext: onNext)
                .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .background(NouriColors.canvas.ignoresSafeArea())
    }
}

#Preview {
    ValuePropView()
}
