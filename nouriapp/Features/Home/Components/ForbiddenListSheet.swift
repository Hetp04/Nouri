//
//  ForbiddenListSheet.swift
//  nouriapp
//
//  Bottom-sheet popup for the user's Forbidden List (Concerns + Allergies).
//

import SwiftUI

// MARK: - Tab Enum

enum ForbiddenTab: CaseIterable {
    case concerns, allergies
    var title: String { self == .concerns ? "Concerns" : "Allergies" }
}

// MARK: - Main Sheet View

struct ForbiddenListSheet: View {
    @EnvironmentObject var onboardingData: OnboardingData
    @Binding var isPresented: Bool
    @State private var activeTab: ForbiddenTab = .concerns
    @State private var isEditing: Bool = false
    @State private var showSelector: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.black.opacity(0.12))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 6)

            // Header row
            HStack(spacing: 12) {
                // Red shield icon
                ZStack {
                    Circle()
                        .fill(Color(red: 1, green: 0.93, blue: 0.93))
                        .frame(width: 40, height: 40)
                    Image(systemName: "shield.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(red: 0.93, green: 0.25, blue: 0.25))
                }

                Text("Forbidden List")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(NouriColors.title)

                Spacer()

                // Secondary action (edit/navigate icon)
                Button(action: { 
                    withAnimation { isEditing.toggle() }
                }) {
                    Image(systemName: isEditing ? "checkmark" : "square.and.pencil")
                        .font(.system(size: 16, weight: isEditing ? .bold : .medium))
                        .foregroundStyle(isEditing ? .white : NouriColors.subtitle)
                        .frame(width: 36, height: 36)
                        .background(isEditing ? NouriColors.brandGreen : NouriColors.iconBgColor, in: Circle())
                }
                .buttonStyle(.plain)

                // Close button
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NouriColors.title)
                        .frame(width: 36, height: 36)
                        .background(NouriColors.iconBgColor, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 16)

            // Segmented tab switch
            ForbiddenTabPicker(activeTab: $activeTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if activeTab == .concerns {
                        ForbiddenSectionContent(
                            activeTab: .concerns,
                            emptyMessage: "No concerns selected yet.",
                            emptyIcon: "shield.slash",
                            isEditing: isEditing
                        )
                    } else {
                        ForbiddenSectionContent(
                            activeTab: .allergies,
                            emptyMessage: "No allergies selected yet.",
                            emptyIcon: "allergens",
                            isEditing: isEditing
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.18), value: activeTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Tab Picker

private struct ForbiddenTabPicker: View {
    @Binding var activeTab: ForbiddenTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ForbiddenTab.allCases, id: \.title) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        activeTab = tab
                    }
                }) {
                    Text(tab.title)
                        .font(.system(size: 15, weight: activeTab == tab ? .bold : .medium))
                        .foregroundStyle(activeTab == tab ? NouriColors.title : NouriColors.subtitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if activeTab == tab {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(NouriColors.iconBgColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Section Content

private struct ForbiddenSectionContent: View {
    let activeTab: ForbiddenTab
    let emptyMessage: String
    let emptyIcon: String
    let isEditing: Bool
    
    @State private var showingCustomAlert = false
    @State private var customInputText = ""
    
    @EnvironmentObject var onboardingData: OnboardingData

    // 1. Core items from registry
    var displayRegistryItems: [TopicItem] {
        if activeTab == .concerns {
            return isEditing ? TopicRegistry.concerns : TopicRegistry.concerns.filter { onboardingData.concerns.contains($0.id) }
        } else {
            return isEditing ? TopicRegistry.allergies : TopicRegistry.allergies.filter { onboardingData.allergies.contains($0.id) }
        }
    }
    
    // 2. Custom mapped items not in registry
    var displayCustomItems: [String] {
        let regIds = Set(activeTab == .concerns ? TopicRegistry.concerns.map(\.id) : TopicRegistry.allergies.map(\.id))
        let userIds = activeTab == .concerns ? onboardingData.concerns : onboardingData.allergies
        return Array(userIds.filter { !regIds.contains($0) }).sorted()
    }
    
    // 3. Other freeform text
    var otherText: String {
        activeTab == .concerns ? onboardingData.otherConcerns : onboardingData.otherAllergies
    }

    var isActuallyEmpty: Bool {
        displayRegistryItems.isEmpty && displayCustomItems.isEmpty && otherText.trimmingCharacters(in: .whitespaces).isEmpty && !isEditing
    }

    var body: some View {
        if isActuallyEmpty {
            EmptyForbiddenState(message: emptyMessage, icon: emptyIcon)
                .padding(.top, 32)
        } else {
            FlowLayout(spacing: 8) {
                
                // --- Registry Render ---
                ForEach(displayRegistryItems, id: \.id) { t in
                    let isSelected = activeTab == .concerns ? onboardingData.concerns.contains(t.id) : onboardingData.allergies.contains(t.id)
                    
                    ZStack(alignment: .topTrailing) {
                        NouriTopicChip(
                            icon: t.icon,
                            text: t.text,
                            imageName: t.imageName,
                            selectedImageName: t.selectedImageName,
                            isSelected: isSelected
                        )
                        .opacity(isEditing && !isSelected ? 0.4 : 1.0)
                        
                        if isEditing && isSelected {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.red, Color.white)
                                .offset(x: 6, y: -6)
                                .shadow(color: .black.opacity(0.1), radius: 2)
                        }
                    }
                    .modifier(JiggleEffect(isJiggling: isEditing && isSelected))
                    .onTapGesture {
                        if isEditing { toggleRegistryItem(id: t.id, currentlySelected: isSelected) }
                    }
                }
                
                // --- Custom ID Render ---
                ForEach(displayCustomItems, id: \.self) { id in
                    ZStack(alignment: .topTrailing) {
                        NouriTopicChip(icon: "checkmark", text: id.capitalized, isSelected: true)
                        if isEditing {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.red, Color.white)
                                .offset(x: 6, y: -6)
                                .shadow(color: .black.opacity(0.1), radius: 2)
                        }
                    }
                    .modifier(JiggleEffect(isJiggling: isEditing))
                    .onTapGesture {
                        if isEditing { deleteCustom(id: id) }
                    }
                }
                
                // --- Other Render ---
                if !otherText.trimmingCharacters(in: .whitespaces).isEmpty {
                    ZStack(alignment: .topTrailing) {
                        NouriTopicChip(
                            icon: "ellipsis",
                            text: otherText.trimmingCharacters(in: .whitespaces),
                            isSelected: true
                        )
                        if isEditing {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.red, Color.white)
                                .offset(x: 6, y: -6)
                                .shadow(color: .black.opacity(0.1), radius: 2)
                        }
                    }
                    .modifier(JiggleEffect(isJiggling: isEditing))
                    .onTapGesture {
                        if isEditing { deleteOther() }
                    }
                }
                
                // --- Add Custom ---
                if isEditing {
                    Button(action: {
                        customInputText = ""
                        showingCustomAlert = true
                    }) {
                        NouriTopicChip(icon: "plus", text: "Add Custom", isSelected: false)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .alert("Add Custom", isPresented: $showingCustomAlert) {
                TextField("E.g. Peanuts, Keto...", text: $customInputText)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    addCustomItem(customInputText)
                }
            } message: {
                Text("Enter a custom restriction manually.")
            }
        }
    }
    
    private func addCustomItem(_ text: String) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanText.isEmpty else { return }
        
        withAnimation {
            if activeTab == .concerns {
                onboardingData.concerns.insert(cleanText)
            } else {
                onboardingData.allergies.insert(cleanText)
            }
        }
        processSave()
    }
    private func toggleRegistryItem(id: String, currentlySelected: Bool) {
        withAnimation {
            if currentlySelected {
                if activeTab == .concerns { onboardingData.concerns.remove(id) } else { onboardingData.allergies.remove(id) }
            } else {
                if activeTab == .concerns { onboardingData.concerns.insert(id) } else { onboardingData.allergies.insert(id) }
            }
        }
        processSave()
    }
    
    private func deleteCustom(id: String) {
        withAnimation {
            if activeTab == .concerns { onboardingData.concerns.remove(id) } else { onboardingData.allergies.remove(id) }
        }
        processSave()
    }
    
    private func deleteOther() {
        withAnimation {
            if activeTab == .concerns { onboardingData.otherConcerns = "" } else { onboardingData.otherAllergies = "" }
        }
        processSave()
    }
    
    private func processSave() {
        Task {
            if let email = KeychainManager.read(key: "user_email") {
                await NouriAuth.shared.saveOnboardingData(email: email, data: onboardingData.toDictionary())
            }
        }
    }
}

// MARK: - Empty State

private struct EmptyForbiddenState: View {
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(NouriColors.subtitle.opacity(0.5))
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(NouriColors.subtitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    ForbiddenListSheet(isPresented: .constant(true))
        .environmentObject(OnboardingData.shared)
        .ignoresSafeArea(edges: .bottom)
}

// MARK: - Jiggle Animation Modifier

struct JiggleEffect: ViewModifier {
    let isJiggling: Bool
    @State private var animate = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isJiggling ? (animate ? 1.5 : -1.5) : 0), anchor: .center)
            .animation(isJiggling ? Animation.easeInOut(duration: 0.14).repeatForever(autoreverses: true) : .default, value: animate)
            .onAppear {
                if isJiggling {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.05)) {
                        animate.toggle()
                    }
                }
            }
            .onChange(of: isJiggling) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.05)) {
                        animate.toggle()
                    }
                } else {
                    animate = false
                }
            }
    }
}
