//
//  NouriTopicChip.swift
//  nouriapp
//
//  Shared selectable pill chip — used on Concerns, Allergies, and Shopping screens.
//

import SwiftUI

struct NouriTopicChip: View {
    var icon: String?
    var text: String
    var imageName: String? = nil
    var selectedImageName: String? = nil
    var isSelected: Bool = false

    // Selected: green tint bg + green border/text/icon  (matches optionChipSelected in RN)
    private var bgColor: Color      { isSelected ? NouriColors.brandGreen.opacity(0.1) : .white }
    private var borderColor: Color  { isSelected ? NouriColors.brandGreen : NouriColors.chipBorder }
    private var fgColor: Color      { isSelected ? NouriColors.brandGreen : NouriColors.chipText }
    private var iconColor: Color    { isSelected ? NouriColors.brandGreen : NouriColors.chipIcon }

    var body: some View {
        HStack(spacing: 6) {
            if let imgName = isSelected ? (selectedImageName ?? imageName) : imageName {
                Image.bundled(imgName)
                    .renderingMode(.template) // Fixes color consistency for custom assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(iconColor)
            } else if let icon = icon {
                Image(systemName: icon)
                    .symbolVariant(isSelected ? .fill : .none)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(iconColor)
            }

            Text(text)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(fgColor)
        }
        .padding(.horizontal, 14)
        .frame(height: 44) // Explicit uniform height avoids irregularities from differing SF symbols
        .background(bgColor)
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(borderColor, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    HStack {
        NouriTopicChip(icon: "leaf", text: "Clean Eating")
        NouriTopicChip(icon: "sparkles", text: "Acne Safe")
    }
    .padding()
}

// MARK: - Selectable Wrapper

struct NouriSelectableChip: View {
    let id: String
    var icon: String? = nil
    let text: String
    var imageName: String? = nil
    var selectedImageName: String? = nil
    
    @Binding var selection: Set<String>
    
    var isSelected: Bool { selection.contains(id) }
    
    var body: some View {
        Button {
            if isSelected {
                selection.remove(id)
            } else {
                selection.insert(id)
            }
        } label: {
            NouriTopicChip(
                icon: icon,
                text: text,
                imageName: imageName,
                selectedImageName: selectedImageName,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isSelected)
    }
}
